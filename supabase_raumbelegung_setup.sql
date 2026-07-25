-- Raum-Zentrale v1.1 · Spvgg Warmbronn 1910 e.V.
-- Einmalig im Supabase SQL Editor ausführen.
-- Standard-PIN für alle Zugänge: 1910

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
create extension if not exists btree_gist;
set search_path = public, extensions;

create table if not exists public.raum_zugaenge (
  id text primary key,
  name text not null,
  farbe text not null default '#3E9142',
  rolle text not null check (rolle in ('abteilung','gaststaette','admin')),
  pin_hash text not null,
  aktiv boolean not null default true,
  geaendert_am timestamptz not null default now()
);

-- Gruppierung der Zugänge auf der Startseite.
alter table public.raum_zugaenge
  add column if not exists gruppe text not null default 'Weitere Abteilungen';
alter table public.raum_zugaenge
  add column if not exists sortierung integer not null default 100;

create table if not exists public.raum_buchungen (
  id uuid primary key default gen_random_uuid(),
  raum_id text not null check (raum_id in ('gross','klein')),
  abteilung_id text not null references public.raum_zugaenge(id),
  titel text not null check (char_length(trim(titel)) between 2 and 120),
  datum date not null,
  von_zeit time not null,
  bis_zeit time not null,
  kontakt text,
  notiz text,
  erstellt_am timestamptz not null default now(),
  geaendert_am timestamptz not null default now(),
  zeitraum tsrange generated always as (
    tsrange(datum + von_zeit, datum + bis_zeit, '[)')
  ) stored,
  constraint raum_buchung_zeit_pruefen check (bis_zeit > von_zeit)
);

create index if not exists raum_buchungen_datum_idx
  on public.raum_buchungen (datum, raum_id);

-- Verhindert Doppelbelegungen auch dann zuverlässig, wenn zwei Nutzer gleichzeitig speichern.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'raum_buchungen_keine_ueberschneidung'
      and conrelid = 'public.raum_buchungen'::regclass
  ) then
    alter table public.raum_buchungen
      add constraint raum_buchungen_keine_ueberschneidung
      exclude using gist (
        raum_id with =,
        zeitraum with &&
      );
  end if;
end $$;

-- Funktionsbezogene Zugänge ohne persönliche Nutzerkonten.
-- Bestehende ID 'fussball' bleibt erhalten und wird zur Abteilungsleitung,
-- damit bereits vorhandene Buchungen weiter korrekt zugeordnet bleiben.
-- ON CONFLICT verändert keine bereits geänderten PINs.
insert into public.raum_zugaenge (id,name,farbe,rolle,pin_hash,gruppe,sortierung) values
  ('vorstand',                 'Vorstand',                        '#0E3B17', 'admin',       crypt('1910', gen_salt('bf')), 'Vereinsführung',      10),
  ('geschaeftsstelle',         'Geschäftsstelle',                 '#365C3B', 'admin',       crypt('1910', gen_salt('bf')), 'Vereinsführung',      20),
  ('fussball',                 'Fußball · Abteilungsleitung',     '#1B5E20', 'abteilung',   crypt('1910', gen_salt('bf')), 'Fußball',              30),
  ('fussball_jugendleitung',   'Fußball · Jugendleitung',         '#3E9142', 'abteilung',   crypt('1910', gen_salt('bf')), 'Fußball',              40),
  ('aktiv_gesund',             'Aktiv & Gesund',                  '#00897B', 'abteilung',   crypt('1910', gen_salt('bf')), 'Weitere Abteilungen',  50),
  ('mountainbike',             'Mountainbike',                    '#7CB342', 'abteilung',   crypt('1910', gen_salt('bf')), 'Weitere Abteilungen',  60),
  ('kinder_jugendsport',       'Kinder- & Jugendsport',           '#039BE5', 'abteilung',   crypt('1910', gen_salt('bf')), 'Weitere Abteilungen',  70),
  ('tischtennis',              'Tischtennis',                     '#F4511E', 'abteilung',   crypt('1910', gen_salt('bf')), 'Weitere Abteilungen',  80),
  ('volleyball_badminton',     'Volleyball & Badminton',          '#8E24AA', 'abteilung',   crypt('1910', gen_salt('bf')), 'Weitere Abteilungen',  90),
  ('chor_gesang',              'Chor & Gesang',                   '#5E35B1', 'abteilung',   crypt('1910', gen_salt('bf')), 'Weitere Abteilungen', 100),
  ('gaststaette',              'Gaststätte 1910',                 '#D99A2B', 'gaststaette', crypt('1910', gen_salt('bf')), 'Gaststätte',           200)
on conflict (id) do update set
  name = excluded.name,
  farbe = excluded.farbe,
  rolle = excluded.rolle,
  gruppe = excluded.gruppe,
  sortierung = excluded.sortierung,
  aktiv = true;

alter table public.raum_zugaenge enable row level security;
alter table public.raum_buchungen enable row level security;

-- Keine direkten Tabellenzugriffe vom Browser. Alles läuft über geprüfte RPC-Funktionen.
revoke all on table public.raum_zugaenge from anon, authenticated;
revoke all on table public.raum_buchungen from anon, authenticated;

drop function if exists public.raum_zugaenge_liste();
create function public.raum_zugaenge_liste()
returns table (
  zugang_id text,
  zugang_name text,
  farbe text,
  rolle text,
  gruppe text,
  sortierung integer
)
language sql
security definer
set search_path = public, extensions
as $$
  select z.id, z.name, z.farbe, z.rolle, z.gruppe, z.sortierung
  from public.raum_zugaenge z
  where z.aktiv = true
  order by z.sortierung, z.name;
$$;

create or replace function public.raum_login(
  p_zugang_id text,
  p_pin text
)
returns table (
  zugang_id text,
  zugang_name text,
  farbe text,
  rolle text
)
language sql
security definer
set search_path = public, extensions
as $$
  select z.id, z.name, z.farbe, z.rolle
  from public.raum_zugaenge z
  where z.id = p_zugang_id
    and z.aktiv = true
    and z.pin_hash = crypt(coalesce(p_pin,''), z.pin_hash)
  limit 1;
$$;

create or replace function public.raum_buchungen_laden(
  p_zugang_id text,
  p_pin text,
  p_von date,
  p_bis date
)
returns table (
  id uuid,
  raum_id text,
  abteilung_id text,
  abteilung_name text,
  farbe text,
  titel text,
  datum date,
  von_zeit time,
  bis_zeit time,
  kontakt text,
  notiz text,
  erstellt_am timestamptz,
  geaendert_am timestamptz,
  darf_bearbeiten boolean
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_rolle text;
begin
  select z.rolle into v_rolle
  from public.raum_zugaenge z
  where z.id = p_zugang_id
    and z.aktiv = true
    and z.pin_hash = crypt(coalesce(p_pin,''), z.pin_hash);

  if not found then
    raise exception 'Zugang oder PIN ist falsch.' using errcode = '28000';
  end if;

  return query
  select
    b.id,
    b.raum_id,
    b.abteilung_id,
    z.name,
    z.farbe,
    b.titel,
    b.datum,
    b.von_zeit,
    b.bis_zeit,
    b.kontakt,
    b.notiz,
    b.erstellt_am,
    b.geaendert_am,
    (b.abteilung_id = p_zugang_id or v_rolle = 'admin')
  from public.raum_buchungen b
  join public.raum_zugaenge z on z.id = b.abteilung_id
  where b.datum between p_von and p_bis
  order by b.datum, b.von_zeit, b.raum_id;
end;
$$;

create or replace function public.raum_buchung_speichern(
  p_zugang_id text,
  p_pin text,
  p_buchung_id uuid,
  p_raum_id text,
  p_datum date,
  p_von_zeit time,
  p_bis_zeit time,
  p_titel text,
  p_kontakt text default null,
  p_notiz text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_rolle text;
  v_id uuid;
  v_eigentuemer text;
  v_konflikt record;
begin
  select z.rolle into v_rolle
  from public.raum_zugaenge z
  where z.id = p_zugang_id
    and z.aktiv = true
    and z.pin_hash = crypt(coalesce(p_pin,''), z.pin_hash);

  if not found then
    raise exception 'Zugang oder PIN ist falsch.' using errcode = '28000';
  end if;

  if p_raum_id not in ('gross','klein') then
    raise exception 'Unbekannter Raum.';
  end if;
  if p_datum is null or p_von_zeit is null or p_bis_zeit is null or p_bis_zeit <= p_von_zeit then
    raise exception 'Datum oder Uhrzeit ist ungültig.';
  end if;
  if char_length(trim(coalesce(p_titel,''))) < 2 then
    raise exception 'Bitte einen Anlass eintragen.';
  end if;

  if p_buchung_id is not null then
    select b.abteilung_id into v_eigentuemer
    from public.raum_buchungen b
    where b.id = p_buchung_id;

    if not found then
      raise exception 'Buchung wurde nicht gefunden.';
    end if;
    if v_eigentuemer <> p_zugang_id and v_rolle <> 'admin' then
      raise exception 'Diese Buchung darf nur die eintragende Abteilung ändern.' using errcode = '42501';
    end if;
  end if;

  select b.id, b.titel, z.name as abteilung_name, b.von_zeit, b.bis_zeit
  into v_konflikt
  from public.raum_buchungen b
  join public.raum_zugaenge z on z.id = b.abteilung_id
  where b.raum_id = p_raum_id
    and b.datum = p_datum
    and (p_buchung_id is null or b.id <> p_buchung_id)
    and b.von_zeit < p_bis_zeit
    and b.bis_zeit > p_von_zeit
  limit 1;

  if found then
    raise exception 'Der Raum ist bereits belegt: % · %–% Uhr (%).',
      v_konflikt.titel,
      to_char(v_konflikt.von_zeit,'HH24:MI'),
      to_char(v_konflikt.bis_zeit,'HH24:MI'),
      v_konflikt.abteilung_name;
  end if;

  if p_buchung_id is null then
    insert into public.raum_buchungen (
      raum_id, abteilung_id, titel, datum, von_zeit, bis_zeit, kontakt, notiz
    ) values (
      p_raum_id, p_zugang_id, trim(p_titel), p_datum, p_von_zeit, p_bis_zeit,
      nullif(trim(coalesce(p_kontakt,'')),''),
      nullif(trim(coalesce(p_notiz,'')),'')
    ) returning id into v_id;
  else
    update public.raum_buchungen
    set raum_id = p_raum_id,
        titel = trim(p_titel),
        datum = p_datum,
        von_zeit = p_von_zeit,
        bis_zeit = p_bis_zeit,
        kontakt = nullif(trim(coalesce(p_kontakt,'')),''),
        notiz = nullif(trim(coalesce(p_notiz,'')),''),
        geaendert_am = now()
    where id = p_buchung_id
    returning id into v_id;
  end if;

  return v_id;
exception
  when exclusion_violation then
    raise exception 'Der gewählte Raum ist in diesem Zeitraum bereits belegt.';
end;
$$;

create or replace function public.raum_buchung_loeschen(
  p_zugang_id text,
  p_pin text,
  p_buchung_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_rolle text;
  v_eigentuemer text;
begin
  select z.rolle into v_rolle
  from public.raum_zugaenge z
  where z.id = p_zugang_id
    and z.aktiv = true
    and z.pin_hash = crypt(coalesce(p_pin,''), z.pin_hash);

  if not found then
    raise exception 'Zugang oder PIN ist falsch.' using errcode = '28000';
  end if;

  select b.abteilung_id into v_eigentuemer
  from public.raum_buchungen b
  where b.id = p_buchung_id;

  if not found then
    return false;
  end if;
  if v_eigentuemer <> p_zugang_id and v_rolle <> 'admin' then
    raise exception 'Diese Buchung darf nur die eintragende Abteilung löschen.' using errcode = '42501';
  end if;

  delete from public.raum_buchungen where id = p_buchung_id;
  return true;
end;
$$;

create or replace function public.raum_pin_aendern(
  p_zugang_id text,
  p_alte_pin text,
  p_neue_pin text
)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if char_length(coalesce(p_neue_pin,'')) < 4 then
    raise exception 'Die neue PIN muss mindestens vier Zeichen haben.';
  end if;

  update public.raum_zugaenge z
  set pin_hash = crypt(p_neue_pin, gen_salt('bf')),
      geaendert_am = now()
  where z.id = p_zugang_id
    and z.aktiv = true
    and z.pin_hash = crypt(coalesce(p_alte_pin,''), z.pin_hash);

  if not found then
    raise exception 'Die bisherige PIN ist falsch.' using errcode = '28000';
  end if;

  return true;
end;
$$;

revoke all on function public.raum_zugaenge_liste() from public;
revoke all on function public.raum_login(text,text) from public;
revoke all on function public.raum_buchungen_laden(text,text,date,date) from public;
revoke all on function public.raum_buchung_speichern(text,text,uuid,text,date,time,time,text,text,text) from public;
revoke all on function public.raum_buchung_loeschen(text,text,uuid) from public;
revoke all on function public.raum_pin_aendern(text,text,text) from public;

grant execute on function public.raum_zugaenge_liste() to anon, authenticated;
grant execute on function public.raum_login(text,text) to anon, authenticated;
grant execute on function public.raum_buchungen_laden(text,text,date,date) to anon, authenticated;
grant execute on function public.raum_buchung_speichern(text,text,uuid,text,date,time,time,text,text,text) to anon, authenticated;
grant execute on function public.raum_buchung_loeschen(text,text,uuid) to anon, authenticated;
grant execute on function public.raum_pin_aendern(text,text,text) to anon, authenticated;

-- Nach dem Ausführen können alle Zugänge einmalig mit 1910 geöffnet werden.
-- Vorstand, Geschäftsstelle, Fußball-Abteilungsleitung und Fußball-Jugendleitung
-- sind eigenständige Zugänge. Es gibt keine persönlichen Konten oder Rollenverknüpfungen.
-- Danach ändert jeder Bereich seine PIN direkt in der Raum-Zentrale.
