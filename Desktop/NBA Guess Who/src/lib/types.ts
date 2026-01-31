export type Party = {
  id: string;
  code: string;
  turn_player_id: string | null;
  winner_id: string | null;
  status: "active" | "finished" | null;
  is_public: boolean;
  game_type: "nba" | "pony" | null;
  created_at: string;
};

export type Player = {
  id: string;
  party_id: string;
  name: string;
  selected_player: string | null;
  joined_at: string;
};

export type Message = {
  id: string;
  party_id: string;
  sender_id: string;
  sender_name: string;
  kind: "question" | "answer";
  text: string | null;
  answer: boolean | null;
  created_at: string;
};
