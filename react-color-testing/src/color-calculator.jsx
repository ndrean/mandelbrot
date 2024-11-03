export const calculateColor = (t) => {
  if (t < 0.5) {
    const scaled = t * 2; // scale t to 0->1 for first half
    return {
      r: Math.round(255 * (1 - scaled)),
      g: Math.round(255 * (1 - scaled / 2)),
      b: Math.round(0 + 128 * scaled),
    };
  } else {
    const scaled = (t - 0.5) * 2; // scale t to 0->1 for second half
    return {
      r: 0,
      g: Math.round(127 * (1 - scaled)),
      b: Math.round(128 * (1 + scaled / 2)),
    };
  }
};
