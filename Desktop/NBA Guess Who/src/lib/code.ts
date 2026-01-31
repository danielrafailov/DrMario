const CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

export const generatePartyCode = (length = 6) => {
  let result = "";
  for (let i = 0; i < length; i += 1) {
    result += CODE_CHARS[Math.floor(Math.random() * CODE_CHARS.length)];
  }
  return result;
};
