"use client";

import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import styles from "./page.module.css";
import { generatePartyCode } from "@/lib/code";
import { isSupabaseConfigured, supabase } from "@/lib/supabaseClient";

const MAX_NAME_LENGTH = 24;
const MAX_CODE_LENGTH = 8;

const getErrorMessage = (error: unknown) => {
  if (error && typeof error === "object" && "message" in error) {
    return String(error.message);
  }
  return "Something went wrong. Please try again.";
};

export default function Home() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [code, setCode] = useState("");
  const [isPublicRoom, setIsPublicRoom] = useState(true);
  const [gameType, setGameType] = useState<"nba" | "pony">("nba");
  const [openRoomLoading, setOpenRoomLoading] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    const storedName = localStorage.getItem("nba-guess-who:name");
    if (storedName) {
      setName(storedName);
    }
  }, []);

  const canSubmit = useMemo(() => {
    return name.trim().length > 0 && !loading;
  }, [name, loading]);

  const createParty = async () => {
    setError("");
    if (!isSupabaseConfigured) {
      setError("Supabase is not configured yet.");
      return;
    }

    const trimmedName = name.trim();
    if (!trimmedName) {
      setError("Enter a name to start a party.");
      return;
    }

    setLoading(true);
    try {
      for (let attempt = 0; attempt < 3; attempt += 1) {
        const nextCode = generatePartyCode();
        const { data: party, error: partyError } = await supabase
          .from("parties")
          .insert({ code: nextCode, is_public: isPublicRoom, game_type: gameType })
          .select()
          .single();

        if (partyError) {
          if (partyError.code === "23505") {
            continue;
          }
          throw partyError;
        }

        const { data: player, error: playerError } = await supabase
          .from("players")
          .insert({ party_id: party.id, name: trimmedName })
          .select()
          .single();

        if (playerError) {
          throw playerError;
        }

        await supabase
          .from("parties")
          .update({ turn_player_id: player.id })
          .eq("id", party.id);

        localStorage.setItem(`nba-guess-who:${nextCode}:playerId`, player.id);
        localStorage.setItem("nba-guess-who:name", trimmedName);
        router.push(`/room/${nextCode}?name=${encodeURIComponent(trimmedName)}`);
        return;
      }

      setError("Could not generate a unique party code. Try again.");
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setLoading(false);
    }
  };

  const joinParty = async () => {
    setError("");
    if (!isSupabaseConfigured) {
      setError("Supabase is not configured yet.");
      return;
    }

    const trimmedName = name.trim();
    const trimmedCode = code.trim().toUpperCase();

    if (!trimmedName) {
      setError("Enter a name before joining a party.");
      return;
    }

    if (!trimmedCode) {
      setError("Enter a party code to join.");
      return;
    }

    setLoading(true);
    try {
      const { data: party, error: partyError } = await supabase
        .from("parties")
        .select("*")
        .eq("code", trimmedCode)
        .single();

      if (partyError || !party) {
        setError("Party not found. Check the code and try again.");
        return;
      }

      const { data: existingPlayers } = await supabase
        .from("players")
        .select("id")
        .eq("party_id", party.id);

      if (existingPlayers && existingPlayers.length >= 2) {
        setError("That party is full.");
        return;
      }

      const { data: player, error: playerError } = await supabase
        .from("players")
        .insert({ party_id: party.id, name: trimmedName })
        .select()
        .single();

      if (playerError) {
        throw playerError;
      }

      localStorage.setItem(`nba-guess-who:${trimmedCode}:playerId`, player.id);
      localStorage.setItem("nba-guess-who:name", trimmedName);
      router.push(`/room/${trimmedCode}?name=${encodeURIComponent(trimmedName)}`);
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setLoading(false);
    }
  };

  const joinOpenRoom = async () => {
    setError("");
    if (!isSupabaseConfigured) {
      setError("Supabase is not configured yet.");
      return;
    }

    const trimmedName = name.trim();
    if (!trimmedName) {
      setError("Enter a name before joining a party.");
      return;
    }

    setOpenRoomLoading(true);
    try {
      let parties: { id: string; code: string }[] | null = null;
      let partiesError: Error | null = null;

      const primary = await supabase
        .from("parties")
        .select("*")
        .eq("is_public", true)
        .eq("status", "active")
        .order("created_at", { ascending: false });

      parties = primary.data;
      partiesError = (primary.error as Error) ?? null;

      if (partiesError && String(partiesError.message).includes("status")) {
        const fallback = await supabase
          .from("parties")
          .select("*")
          .eq("is_public", true)
          .order("created_at", { ascending: false });
        parties = fallback.data;
        partiesError = (fallback.error as Error) ?? null;
      }

      if (partiesError || !parties || parties.length === 0) {
        setError("No open rooms right now.");
        return;
      }

      const playerCounts = await Promise.all(
        parties.map(async (party) => {
          const { data } = await supabase
            .from("players")
            .select("id")
            .eq("party_id", party.id);
          return { party, count: data?.length ?? 0 };
        })
      );

      const open = playerCounts.find((entry) => entry.count < 2);
      if (!open) {
        setError("No open rooms right now.");
        return;
      }

      const { data: player, error: playerError } = await supabase
        .from("players")
        .insert({ party_id: open.party.id, name: trimmedName })
        .select()
        .single();

      if (playerError) {
        throw playerError;
      }

      localStorage.setItem(
        `nba-guess-who:${open.party.code}:playerId`,
        player.id
      );
      localStorage.setItem("nba-guess-who:name", trimmedName);
      router.push(
        `/room/${open.party.code}?name=${encodeURIComponent(trimmedName)}`
      );
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setOpenRoomLoading(false);
    }
  };

  return (
    <div className={styles.page}>
      <main className={styles.main}>
        <header className={styles.header}>
          <p className={styles.kicker}>NBA Guess Who</p>
          <h1>Ask yes/no questions, one turn at a time.</h1>
          <p className={styles.subhead}>
            Create a party, share the code, and take turns asking questions in
            the chat. The other player answers yes or no.
          </p>
        </header>

        {!isSupabaseConfigured && (
          <div className={styles.notice}>
            Add your Supabase keys in <code>.env.local</code> to enable parties
            and real-time chat.
          </div>
        )}

        <section className={styles.card}>
          <div className={styles.formRow}>
            <label htmlFor="name">Your name</label>
            <input
              id="name"
              className={styles.input}
              placeholder="Enter your name"
              value={name}
              maxLength={MAX_NAME_LENGTH}
              onChange={(event) => setName(event.target.value)}
            />
          </div>

          <div className={styles.grid}>
            <div className={styles.panel}>
              <h2>Create party</h2>
              <p>Start a new room and invite a friend.</p>
              <label className={styles.formRow}>
                <span>Game set</span>
                <select
                  className={styles.input}
                  value={gameType}
                  onChange={(event) =>
                    setGameType(event.target.value as "nba" | "pony")
                  }
                >
                  <option value="nba">NBA Guess Who</option>
                  <option value="pony">My Little Pony Guess Who</option>
                </select>
              </label>
              <label className={styles.toggleRow}>
                <input
                  type="checkbox"
                  checked={isPublicRoom}
                  onChange={(event) => setIsPublicRoom(event.target.checked)}
                />
                <span>Public room (shows up in open rooms)</span>
              </label>
              <button
                className={styles.primary}
                onClick={createParty}
                disabled={!canSubmit}
              >
                {loading ? "Creating..." : "Create party"}
              </button>
            </div>
            <div className={styles.panel}>
              <h2>Join party</h2>
              <p>Have a code? Join an existing room.</p>
              <input
                className={styles.input}
                placeholder="Party code"
                value={code}
                maxLength={MAX_CODE_LENGTH}
                onChange={(event) => setCode(event.target.value.toUpperCase())}
              />
              <button
                className={styles.secondary}
                onClick={joinParty}
                disabled={!canSubmit}
              >
                {loading ? "Joining..." : "Join party"}
              </button>
              <button
                className={styles.ghost}
                onClick={joinOpenRoom}
                disabled={!canSubmit || openRoomLoading}
              >
                {openRoomLoading ? "Searching..." : "Join open room"}
              </button>
            </div>
          </div>

          {error && <div className={styles.error}>{error}</div>}
        </section>
      </main>
    </div>
  );
}
