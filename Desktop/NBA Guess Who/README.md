# NBA Guess Who

Simple, turn-based NBA Guess Who for two players. Create a party, share the
code, then take turns asking yes/no questions in a live chat.

## Tech stack

- Next.js (App Router)
- Supabase (Postgres + realtime)

## Local setup

1. Install dependencies:

```bash
npm install
```

2. Create a Supabase project and add the following tables:

```sql
create table if not exists parties (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  turn_player_id uuid,
  winner_id uuid,
  status text default 'active',
  is_public boolean default true,
  game_type text default 'nba',
  created_at timestamp with time zone default now()
);

create table if not exists players (
  id uuid primary key default gen_random_uuid(),
  party_id uuid references parties(id) on delete cascade,
  name text not null,
  selected_player text,
  joined_at timestamp with time zone default now()
);

create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  party_id uuid references parties(id) on delete cascade,
  sender_id uuid not null,
  sender_name text not null,
  kind text not null check (kind in ('question', 'answer')),
  text text,
  answer boolean,
  created_at timestamp with time zone default now()
);
```

3. Enable realtime for `parties`, `players`, and `messages` in Supabase.
   If Realtime (replication) is not available on your plan yet, the app
   still works using polling every few seconds.

4. Create a `.env.local` file in the project root:

```
NEXT_PUBLIC_SUPABASE_URL=your-project-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

5. Run the dev server:

```bash
npm run dev
```

Open `http://localhost:3000`.

## Notes

- The host creates the party and starts the first turn.
- The answerer ends the turn; the next turn goes to the answerer.

## Schema updates for existing projects

If you already created the tables, run:

```sql
alter table parties add column if not exists winner_id uuid;
alter table parties add column if not exists status text default 'active';
alter table parties add column if not exists is_public boolean default true;
alter table parties add column if not exists game_type text default 'nba';
alter table players add column if not exists selected_player text;
```
