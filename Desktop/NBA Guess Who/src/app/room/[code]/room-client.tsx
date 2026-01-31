"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import styles from "./room.module.css";
import { isSupabaseConfigured, supabase } from "@/lib/supabaseClient";
import type { Message, Party, Player } from "@/lib/types";

type RoomClientProps = {
  code: string;
};

const playerStorageKey = (code: string) => `nba-guess-who:${code}:playerId`;

const getErrorMessage = (error: unknown) => {
  if (error && typeof error === "object" && "message" in error) {
    return String(error.message);
  }
  return "Something went wrong. Please try again.";
};

const updateList = <T extends { id: string }>(items: T[], next: T) => {
  const existingIndex = items.findIndex((item) => item.id === next.id);
  if (existingIndex === -1) {
    return [...items, next];
  }
  const updated = [...items];
  updated[existingIndex] = next;
  return updated;
};

const NBA_IMAGES = [
  // Point guards
  "MagicJohnson.avif",
  "JohnStockton.jpeg",
  "GaryPayton.avif",
  "OscarRobertson.jpeg",
  "StephenCurry.webp",
  // Shooting guards
  "MichaelJordan.png",
  "KobeBryant.png",
  "DwyaneWade.jpeg",
  "AllenIverson.webp",
  "Shai.jpeg",
  // Small forwards
  "LebronJames.avif",
  "LarryBird.avif",
  "KawhiLeonard.webp",
  "VinceCarter.png",
  "TracyMcGrady.webp",
  // Power forwards
  "Giannis.avif",
  "Dirk.webp",
  "Tim Duncan.webp",
  "BillRussell.jpeg",
  "KevinDurant.webp",
  // Centers
  "Kareem.jpeg",
  "Hakeem.jpeg",
  "Shaq.jpeg",
  "WiltChamberlain.jpeg",
  "Yao Ming.webp",
];

const PONY_IMAGES = [
  "applebloom.png",
  "applejack.png",
  "chrysalis.jpeg",
  "CozyGlow.png",
  "DiamondTiara.jpeg",
  "Discord.jpeg",
  "fluttershy.jpeg",
  "Lord Tirek.jpeg",
  "PinkyPie.jpeg",
  "Prince Shining Armor.jpeg",
  "PrincessCandice.jpeg",
  "princessCelestia.jpeg",
  "PrincessFlurryHeart.jpeg",
  "princessluna.jpeg",
  "rainbowdash.png",
  "Rarity.jpeg",
  "Scootaloo.png",
  "SilverSpoon.jpeg",
  "Sombra.webp",
  "Spike.png",
  "StarlightGlimmer.webp",
  "SweetieBelle.jpeg",
  "Trixie.png",
  "twilight.webp",
  "Zecora.webp",
];

const PONY_NAME_OVERRIDES: Record<string, string> = {
  applebloom: "Apple Bloom",
  applejack: "Applejack",
  chrysalis: "Queen Chrysalis",
  CozyGlow: "Cozy Glow",
  DiamondTiara: "Diamond Tiara",
  Discord: "Discord",
  fluttershy: "Fluttershy",
  "Lord Tirek": "Lord Tirek",
  PinkyPie: "Pinkie Pie",
  "Prince Shining Armor": "Prince Shining Armor",
  PrincessCandice: "Princess Cadance",
  princessCelestia: "Princess Celestia",
  PrincessFlurryHeart: "Princess Flurry Heart",
  princessluna: "Princess Luna",
  rainbowdash: "Rainbow Dash",
  Rarity: "Rarity",
  Scootaloo: "Scootaloo",
  SilverSpoon: "Silver Spoon",
  Sombra: "King Sombra",
  Spike: "Spike",
  StarlightGlimmer: "Starlight Glimmer",
  SweetieBelle: "Sweetie Belle",
  Trixie: "Trixie",
  twilight: "Twilight Sparkle",
  Zecora: "Zecora",
};

const formatPlayerName = (fileName: string, gameType: GameType) => {
  const base = fileName.replace(/\.[^/.]+$/, "");
  if (gameType === "pony") {
    return PONY_NAME_OVERRIDES[base] ?? base;
  }
  return base
    .replace(/[_-]/g, " ")
    .replace(/([a-z])([A-Z])/g, "$1 $2");
};

const NBA_POSITIONS: Record<string, string> = {
  AllenIverson: "SG/PG",
  BillRussell: "C/PF",
  Dirk: "PF/C",
  DwyaneWade: "SG/PG",
  GaryPayton: "PG/SG",
  Giannis: "PF/SF",
  Hakeem: "C/PF",
  JohnStockton: "PG",
  Kareem: "C",
  KawhiLeonard: "SF/SG",
  KevinDurant: "PF/SF",
  KobeBryant: "SG/SF",
  LarryBird: "SF/PF",
  LebronJames: "SF/PF",
  MagicJohnson: "PG",
  MichaelJordan: "SG",
  OscarRobertson: "PG/SG",
  Shai: "SG/PG",
  Shaq: "C",
  StephenCurry: "PG/SG",
  TimDuncan: "PF/C",
  TracyMcGrady: "SG/SF",
  VinceCarter: "SG/SF",
  WiltChamberlain: "C",
  YaoMing: "C",
};

const GAME_CONFIG = {
  nba: {
    label: "NBA",
    imagePath: "/Players/",
    images: NBA_IMAGES,
    positions: NBA_POSITIONS,
  },
  pony: {
    label: "My Little Pony",
    imagePath: "/MyLittlePony/",
    images: PONY_IMAGES,
  },
} as const;

type GameType = keyof typeof GAME_CONFIG;

const getPlayerPosition = (fileName: string, gameType: GameType) => {
  const positions = GAME_CONFIG[gameType].positions;
  if (!positions) {
    return "";
  }
  const key = fileName.replace(/\.[^/.]+$/, "");
  return positions[key] ?? "";
};

export default function RoomClient({ code }: RoomClientProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const nameFromQuery = searchParams.get("name") ?? "";

  const [party, setParty] = useState<Party | null>(null);
  const [players, setPlayers] = useState<Player[]>([]);
  const [messages, setMessages] = useState<Message[]>([]);
  const [playerId, setPlayerId] = useState<string | null>(null);
  const [nameInput, setNameInput] = useState(nameFromQuery);
  const [question, setQuestion] = useState("");
  const [loading, setLoading] = useState(true);
  const [initialLoaded, setInitialLoaded] = useState(false);
  const [error, setError] = useState("");
  const [creatingPlayer, setCreatingPlayer] = useState(false);
  const [copied, setCopied] = useState(false);
  const [flipped, setFlipped] = useState<Record<string, boolean>>({});
  const [selectionInput, setSelectionInput] = useState("");
  const [guessInput, setGuessInput] = useState("");
  const [actionError, setActionError] = useState("");
  const [countdown, setCountdown] = useState<number | "GO" | null>(null);
  const [turnTimeLeft, setTurnTimeLeft] = useState(30);
  const [turnExpired, setTurnExpired] = useState(false);

  useEffect(() => {
    if (nameFromQuery.trim()) {
      return;
    }

    const storedName = localStorage.getItem("nba-guess-who:name");
    if (storedName) {
      setNameInput(storedName);
    }
  }, [nameFromQuery]);

  useEffect(() => {
    if (!isSupabaseConfigured) {
      setLoading(false);
      return;
    }

    const storedPlayerId = localStorage.getItem(playerStorageKey(code));
    if (storedPlayerId) {
      setPlayerId(storedPlayerId);
    }
  }, [code]);

  const refreshRoom = useCallback(async () => {
    if (!isSupabaseConfigured) {
      return;
    }

    if (!initialLoaded) {
      setLoading(true);
    }

    const { data: partyData, error: partyError } = await supabase
      .from("parties")
      .select("*")
      .eq("code", code)
      .single();

    if (partyError || !partyData) {
      setError("Party not found.");
      if (!initialLoaded) {
        setLoading(false);
      }
      return;
    }

    const [playersResponse, messagesResponse] = await Promise.all([
      supabase
        .from("players")
        .select("*")
        .eq("party_id", partyData.id)
        .order("joined_at", { ascending: true }),
      supabase
        .from("messages")
        .select("*")
        .eq("party_id", partyData.id)
        .order("created_at", { ascending: true }),
    ]);

    setParty(partyData);
    setPlayers(playersResponse.data ?? []);
    setMessages(messagesResponse.data ?? []);
    setError("");

    if (!initialLoaded) {
      setInitialLoaded(true);
      setLoading(false);
    }
  }, [code, initialLoaded]);

  useEffect(() => {
    refreshRoom();

    const interval = setInterval(refreshRoom, 4000);

    return () => {
      clearInterval(interval);
    };
  }, [refreshRoom]);

  useEffect(() => {
    if (!party || !isSupabaseConfigured) {
      return;
    }

    const partyChannel = supabase
      .channel(`party:${party.id}`)
      .on(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "parties",
          filter: `id=eq.${party.id}`,
        },
        (payload) => {
          setParty(payload.new as Party);
        }
      )
      .subscribe();

    const playersChannel = supabase
      .channel(`players:${party.id}`)
      .on(
        "postgres_changes",
        {
          event: "*",
          schema: "public",
          table: "players",
          filter: `party_id=eq.${party.id}`,
        },
        (payload) => {
          if (payload.eventType === "INSERT") {
            setPlayers((current) => updateList(current, payload.new as Player));
          } else if (payload.eventType === "UPDATE") {
            setPlayers((current) => updateList(current, payload.new as Player));
          } else if (payload.eventType === "DELETE") {
            setPlayers((current) =>
              current.filter((player) => player.id !== payload.old.id)
            );
          }
        }
      )
      .subscribe();

    const messagesChannel = supabase
      .channel(`messages:${party.id}`)
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "messages",
          filter: `party_id=eq.${party.id}`,
        },
        (payload) => {
          setMessages((current) => [...current, payload.new as Message]);
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(partyChannel);
      supabase.removeChannel(playersChannel);
      supabase.removeChannel(messagesChannel);
    };
  }, [party]);

  const joinRoom = useCallback(async () => {
    if (!party || playerId || creatingPlayer || !nameInput.trim()) {
      return;
    }

    setCreatingPlayer(true);
    setError("");

    try {
      const { data: existingPlayers } = await supabase
        .from("players")
        .select("id")
        .eq("party_id", party.id);

      if (existingPlayers && existingPlayers.length >= 2) {
        setError("This party is full.");
        return;
      }

      const { data: player, error: playerError } = await supabase
        .from("players")
        .insert({ party_id: party.id, name: nameInput.trim() })
        .select()
        .single();

      if (playerError) {
        throw playerError;
      }

      localStorage.setItem(playerStorageKey(code), player.id);
      localStorage.setItem("nba-guess-who:name", nameInput.trim());
      setPlayerId(player.id);

      if (!party.turn_player_id) {
        await supabase
          .from("parties")
          .update({ turn_player_id: player.id })
          .eq("id", party.id);
      }
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setCreatingPlayer(false);
    }
  }, [party, playerId, creatingPlayer, nameInput, code]);

  useEffect(() => {
    if (!party || playerId || creatingPlayer) {
      return;
    }

    if (nameFromQuery.trim()) {
      joinRoom();
    }
  }, [party, playerId, creatingPlayer, nameFromQuery, joinRoom]);

  const gameType = (party?.game_type ?? "nba") as GameType;
  const gameConfig = useMemo(() => {
    return GAME_CONFIG[gameType] ?? GAME_CONFIG.nba;
  }, [gameType]);
  const playerOptions = useMemo(
    () =>
      gameConfig.images.map((file) => ({
        file,
        name: formatPlayerName(file, gameType),
      })),
    [gameConfig, gameType]
  );

  const me = useMemo(() => {
    return players.find((player) => player.id === playerId) ?? null;
  }, [players, playerId]);

  const opponent = useMemo(() => {
    return players.find((player) => player.id !== playerId) ?? null;
  }, [players, playerId]);

  const selectedCount = useMemo(() => {
    return players.filter((player) => Boolean(player.selected_player)).length;
  }, [players]);

  const firstSelectedPlayer = useMemo(() => {
    return players.find((player) => Boolean(player.selected_player)) ?? null;
  }, [players]);

  const currentTurn = useMemo(() => {
    return players.find((player) => player.id === party?.turn_player_id) ?? null;
  }, [players, party]);

  const unansweredQuestion = useMemo(() => {
    let pending: Message | null = null;
    messages.forEach((message) => {
      if (message.kind === "question") {
        pending = message;
      }
      if (message.kind === "answer") {
        pending = null;
      }
    });
    return pending;
  }, [messages]);

  const gameFinished = Boolean(party?.winner_id);
  const bothSelected =
    players.length >= 2 &&
    players.every((player) => Boolean(player.selected_player));

  const canSelectNow = Boolean(
    party &&
      playerId &&
      !me?.selected_player &&
      ((selectedCount === 0 && party.turn_player_id === playerId) ||
        (selectedCount === 1 && firstSelectedPlayer?.id !== playerId))
  );

  const selectionStatus = (() => {
    if (bothSelected) {
      return "Both players are ready.";
    }
    if (selectedCount === 0) {
      return party?.turn_player_id === playerId
        ? "It's your turn to pick a player."
        : "Wait for the first player to pick.";
    }
    if (selectedCount === 1) {
      return firstSelectedPlayer?.id === playerId
        ? "Waiting for the other player to pick."
        : "It's your turn to pick a player.";
    }
    return "";
  })();

  const canAsk = Boolean(
    party &&
      playerId &&
      party.turn_player_id === playerId &&
      !unansweredQuestion &&
      bothSelected &&
      !gameFinished
  );
  const canAnswer = Boolean(
    party &&
      playerId &&
      party.turn_player_id !== playerId &&
      unansweredQuestion &&
      bothSelected &&
      !gameFinished
  );

  useEffect(() => {
    if (!bothSelected || gameFinished) {
      return;
    }

    setCountdown(3);
    let current = 3;
    const interval = setInterval(() => {
      current -= 1;
      if (current > 0) {
        setCountdown(current);
      } else if (current === 0) {
        setCountdown("GO");
      } else {
        setCountdown(null);
        clearInterval(interval);
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [bothSelected, gameFinished]);

  useEffect(() => {
    if (!party || !bothSelected || gameFinished) {
      return;
    }

    setTurnTimeLeft(30);
    setTurnExpired(false);
  }, [party?.turn_player_id, unansweredQuestion?.id, bothSelected, gameFinished]);

  useEffect(() => {
    if (!party || !bothSelected || gameFinished || !canAsk || turnExpired) {
      return;
    }

    if (turnTimeLeft <= 0) {
      if (opponent) {
        setTurnExpired(true);
        supabase
          .from("parties")
          .update({ turn_player_id: opponent.id })
          .eq("id", party.id);
      }
      return;
    }

    const timer = setInterval(() => {
      setTurnTimeLeft((current) => current - 1);
    }, 1000);

    return () => clearInterval(timer);
  }, [
    party,
    opponent,
    bothSelected,
    gameFinished,
    canAsk,
    turnExpired,
    turnTimeLeft,
  ]);

  const sendQuestion = async () => {
    if (!party || !playerId || !canAsk) {
      return;
    }

    const trimmed = question.trim();
    if (!trimmed) {
      return;
    }

    setQuestion("");
    await supabase.from("messages").insert({
      party_id: party.id,
      sender_id: playerId,
      sender_name: me?.name ?? "Player",
      kind: "question",
      text: trimmed,
      answer: null,
    });
  };

  const sendAnswer = async (answer: boolean) => {
    if (!party || !playerId || !canAnswer) {
      return;
    }

    await supabase.from("messages").insert({
      party_id: party.id,
      sender_id: playerId,
      sender_name: me?.name ?? "Player",
      kind: "answer",
      text: answer ? "Yes" : "No",
      answer,
    });

    await supabase
      .from("parties")
      .update({ turn_player_id: playerId })
      .eq("id", party.id);
  };

  const selectSecretPlayer = async () => {
    if (!party || !playerId || !selectionInput.trim()) {
      return;
    }

    setActionError("");

    if (!canSelectNow) {
      setActionError("Wait for the other player to pick first.");
      return;
    }

    const { error: updateError } = await supabase
      .from("players")
      .update({ selected_player: selectionInput.trim() })
      .eq("id", playerId);

    if (updateError) {
      setActionError(getErrorMessage(updateError));
      return;
    }

    setPlayers((current) =>
      current.map((player) =>
        player.id === playerId
          ? { ...player, selected_player: selectionInput.trim() }
          : player
      )
    );
    setSelectionInput("");
  };

  const makeGuess = async () => {
    if (!party || !playerId || !guessInput.trim() || !opponent) {
      return;
    }

    setActionError("");

    const guessed = guessInput.trim();
    const match = playerOptions.find(
      (option) => option.name.toLowerCase() === guessed.toLowerCase()
    );

    if (!match) {
      setActionError("Pick a player from the list.");
      return;
    }

    if (!opponent.selected_player) {
      setActionError("Opponent has not selected a player yet.");
      return;
    }

    const isCorrect =
      opponent.selected_player.toLowerCase() === match.name.toLowerCase();
    const winnerId = isCorrect ? playerId : opponent.id;

    let { error: guessError } = await supabase
      .from("parties")
      .update({ winner_id: winnerId, status: "finished" })
      .eq("id", party.id);

    if (guessError) {
      if (String(guessError.message).includes("winner_id")) {
        setActionError(
          "Missing winner_id column. Run the SQL update and reload schema cache."
        );
        return;
      }
      if (String(guessError.message).includes("status")) {
        const retry = await supabase
          .from("parties")
          .update({ winner_id: winnerId })
          .eq("id", party.id);
        guessError = retry.error ?? null;
      }
      if (guessError) {
        setActionError(getErrorMessage(guessError));
        return;
      }
    }
  };

  const copyCode = async () => {
    try {
      await navigator.clipboard.writeText(code.toUpperCase());
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      setCopied(false);
    }
  };

  const leaveParty = async () => {
    if (!party || !playerId) {
      router.push("/");
      return;
    }

    await supabase.from("players").delete().eq("id", playerId);

    const { data: remaining } = await supabase
      .from("players")
      .select("id")
      .eq("party_id", party.id);

    if (!remaining || remaining.length === 0) {
      await supabase.from("messages").delete().eq("party_id", party.id);
      await supabase.from("parties").delete().eq("id", party.id);
    }

    localStorage.removeItem(playerStorageKey(code));
    router.push("/");
  };

  const rematch = async () => {
    if (!party || !playerId) {
      return;
    }

    const messagesDelete = await supabase
      .from("messages")
      .delete()
      .eq("party_id", party.id);
    if (messagesDelete.error) {
      setActionError(getErrorMessage(messagesDelete.error));
      return;
    }

    const playersReset = await supabase
      .from("players")
      .update({ selected_player: null })
      .eq("party_id", party.id);
    if (playersReset.error) {
      setActionError(getErrorMessage(playersReset.error));
      return;
    }

    let partyReset = await supabase
      .from("parties")
      .update({ winner_id: null, status: "active", turn_player_id: playerId })
      .eq("id", party.id);

    if (partyReset.error && String(partyReset.error.message).includes("status")) {
      partyReset = await supabase
        .from("parties")
        .update({ winner_id: null, turn_player_id: playerId })
        .eq("id", party.id);
    }

    if (
      partyReset.error &&
      String(partyReset.error.message).includes("winner_id")
    ) {
      partyReset = await supabase
        .from("parties")
        .update({ turn_player_id: playerId })
        .eq("id", party.id);
    }

    if (partyReset.error) {
      setActionError(getErrorMessage(partyReset.error));
      return;
    }

    setFlipped({});
    setGuessInput("");
    setSelectionInput("");
    setActionError("");
  };

  const toggleFlip = (file: string) => {
    setFlipped((current) => ({
      ...current,
      [file]: !current[file],
    }));
  };

  const handleTileClick = (file: string) => {
    const name = formatPlayerName(file, gameType);
    if (!me?.selected_player) {
      if (!canSelectNow) {
        setActionError("Wait for the other player to pick first.");
        return;
      }
      setSelectionInput((current) => (current === name ? "" : name));
      setActionError("");
      return;
    }
    if (!bothSelected) {
      return;
    }
    toggleFlip(file);
  };

  if (!isSupabaseConfigured) {
    return (
      <div className={styles.page}>
        <div className={styles.notice}>
          Add your Supabase keys in <code>.env.local</code> to enable parties.
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className={styles.page}>
        <div className={styles.notice}>Loading room...</div>
      </div>
    );
  }

  if (error || !party) {
    return (
      <div className={styles.page}>
        <div className={styles.notice}>{error || "Party not found."}</div>
        <button className={styles.secondary} onClick={() => router.push("/")}>
          Back to home
        </button>
      </div>
    );
  }

  const selectedCard = playerOptions.find(
    (option) => option.name === me?.selected_player
  );

  const winnerMessage =
    party.winner_id === playerId ? "You won!" : "You lost.";

  return (
    <div className={styles.page}>
      <div className={styles.shell}>
        <header className={styles.header}>
          <div className={styles.headerTop}>
            <div>
              <p className={styles.kicker}>Party code</p>
              <div className={styles.codeRow}>
                <span className={styles.code}>{code.toUpperCase()}</span>
                <button className={styles.ghost} onClick={copyCode}>
                  {copied ? "Copied" : "Copy"}
                </button>
              </div>
            </div>
            <div className={styles.turn}>
              <p>Turn</p>
              <strong>{currentTurn ? currentTurn.name : "Waiting..."}</strong>
            </div>
            <button className={styles.ghost} onClick={leaveParty}>
              Leave party
            </button>
          </div>
          <div className={styles.headerPlayers}>
            <span>Players:</span>
            <div className={styles.playerNames}>
              {players.length === 0 && <span>Waiting for players...</span>}
              {players.map((player) => (
                <span key={player.id}>
                  {player.name}
                  {player.id === playerId && " (You)"}
                </span>
              ))}
            </div>
          </div>
        </header>

        <section className={styles.mainRow}>
          <div className={styles.leftColumn}>
            <div className={styles.boardPanel}>
              <div className={styles.boardHeader}>
                <h2>Player board</h2>
                <p>Use yes/no questions to narrow it down.</p>
              </div>
              <div className={styles.selectionCard}>
                <p>Your selected card</p>
                {selectedCard ? (
                  <div className={styles.selectedCard}>
                    <img
                      src={encodeURI(`/Players/${selectedCard.file}`)}
                      alt={selectedCard.name}
                    />
                    <div className={styles.selectedText}>
                      <span>{selectedCard.name}</span>
                      <span className={styles.position}>
                        {getPlayerPosition(selectedCard.file)}
                      </span>
                    </div>
                  </div>
                ) : (
                  <div className={styles.selectRow}>
                    <div className={styles.selectedHint}>
                      {selectionInput
                        ? `Selected: ${selectionInput}`
                        : "Click a card to select."}
                    </div>
                    <button
                      className={styles.primary}
                      onClick={selectSecretPlayer}
                      disabled={
                        !selectionInput.trim() ||
                        Boolean(selectedCard) ||
                        !canSelectNow
                      }
                    >
                      Lock in selection
                    </button>
                  </div>
                )}
              </div>
              {!bothSelected && (
                <div className={styles.notice}>
                  {selectionStatus}
                </div>
              )}
              <div className={styles.playerGrid}>
                {gameConfig.images.map((file) => {
                  const name = formatPlayerName(file, gameType);
                  const src = encodeURI(`${gameConfig.imagePath}${file}`);
                  const isFlipped = Boolean(flipped[file]);
                  const isSelected = selectionInput === name;
                  const isLocked = selectedCard?.file === file && !bothSelected;
                  const shouldDim =
                    Boolean(selectedCard) && !bothSelected && !isLocked;
                  const positionText = getPlayerPosition(file, gameType);
                  return (
                    <button
                      key={file}
                      type="button"
                      className={`${styles.playerTile} ${
                        isFlipped ? styles.flipped : ""
                      } ${isSelected ? styles.tileSelected : ""} ${
                        isLocked ? styles.tileLocked : ""
                      } ${shouldDim ? styles.tileDim : ""}`}
                      onClick={() => handleTileClick(file)}
                      aria-pressed={isFlipped}
                    >
                      <div className={styles.cardInner}>
                        <div className={styles.cardFace}>
                          <img
                            className={styles.playerImage}
                            src={src}
                            alt={name}
                            loading="lazy"
                          />
                          <span className={styles.playerName}>{name}</span>
                          {positionText && (
                            <span className={styles.playerPosition}>
                              {positionText}
                            </span>
                          )}
                        </div>
                        <div className={styles.cardBack} />
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          </div>

          <div className={styles.rightColumn}>
            <div className={styles.panel}>
              <h2>Chat</h2>
              <div className={styles.turnTimer}>
                {canAsk ? (
                  <span>Time left: {turnTimeLeft}s</span>
                ) : (
                  <span>Waiting on {currentTurn?.name ?? "player"}...</span>
                )}
              </div>
              <div className={styles.chat}>
                {messages.length === 0 && (
                  <div className={styles.empty}>
                    No questions yet. Ask the first one!
                  </div>
                )}
                {messages.map((message) => (
                  <div
                    key={message.id}
                    className={
                      message.sender_id === playerId
                        ? styles.myMessage
                        : styles.theirMessage
                    }
                  >
                    <span className={styles.sender}>{message.sender_name}</span>
                    <span className={styles.body}>
                      {message.kind === "answer"
                        ? message.text
                        : message.text}
                    </span>
                  </div>
                ))}
              </div>

              <div className={styles.controls}>
                {actionError && <div className={styles.error}>{actionError}</div>}
                {!playerId && (
                  <div className={styles.joinRow}>
                    <input
                      className={styles.input}
                      placeholder="Enter your name"
                      value={nameInput}
                      onChange={(event) => setNameInput(event.target.value)}
                    />
                    <button
                      className={styles.primary}
                      disabled={creatingPlayer || !nameInput.trim()}
                      onClick={joinRoom}
                    >
                      {creatingPlayer ? "Joining..." : "Join room"}
                    </button>
                  </div>
                )}

                {playerId && (
                  <>
                    <div className={styles.guessRow}>
                      <select
                        className={styles.select}
                        value={guessInput}
                        onChange={(event) => setGuessInput(event.target.value)}
                        disabled={!canAsk}
                      >
                        <option value="">Guess a player</option>
                        {playerOptions.map((option) => (
                          <option key={option.file} value={option.name}>
                            {option.name}
                          </option>
                        ))}
                      </select>
                      <button
                        className={styles.secondary}
                        onClick={makeGuess}
                        disabled={!canAsk || !guessInput.trim()}
                      >
                        Guess
                      </button>
                    </div>
                    <div className={styles.askRow}>
                      <input
                        className={styles.input}
                        placeholder={
                          canAsk
                            ? "Type your yes/no question"
                            : "Wait for your turn"
                        }
                        value={question}
                        onChange={(event) => setQuestion(event.target.value)}
                        disabled={!canAsk}
                        onKeyDown={(event) => {
                          if (event.key === "Enter") {
                            sendQuestion();
                          }
                        }}
                      />
                      <button
                        className={styles.primary}
                        onClick={sendQuestion}
                        disabled={!canAsk}
                      >
                        Ask
                      </button>
                    </div>

                    {unansweredQuestion && (
                      <div className={styles.answerRow}>
                        <p>
                          {unansweredQuestion.sender_name} asked:{" "}
                          <strong>{unansweredQuestion.text}</strong>
                        </p>
                        <div className={styles.answerButtons}>
                          <button
                            className={styles.secondary}
                            onClick={() => sendAnswer(true)}
                            disabled={!canAnswer}
                          >
                            Yes
                          </button>
                          <button
                            className={styles.secondary}
                            onClick={() => sendAnswer(false)}
                            disabled={!canAnswer}
                          >
                            No
                          </button>
                        </div>
                      </div>
                    )}
                  </>
                )}
              </div>
            </div>
          </div>
        </section>
        {gameFinished && (
          <div className={styles.resultOverlay}>
            <div className={styles.resultCard}>
              <h2>{winnerMessage}</h2>
              <p>
                {party.winner_id === playerId
                  ? "Nice guess. Play again?"
                  : "Good game. Want a rematch?"}
              </p>
              <div className={styles.resultActions}>
                <button className={styles.primary} onClick={rematch}>
                  Rematch
                </button>
                <button className={styles.secondary} onClick={leaveParty}>
                  Home
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
      {countdown !== null && (
        <div className={styles.countdownOverlay}>
          <div className={styles.countdownText}>
            {countdown === "GO" ? "GO!" : countdown}
          </div>
        </div>
      )}
    </div>
  );
}
