import { useState } from "react";
import { calculateColor } from "./color-calculator";

export const ColorTransition = () => {
  const [time, setTime] = useState(0);

  const currentColor = calculateColor(time);
  const colorString = `rgb(${currentColor.r}, ${currentColor.g}, ${currentColor.b})`;

  return (
    <div className="w-full max-w-2xl">
      <header>
        <p className="text-4xl">Color Transition Preview</p>
      </header>
      <div>
        <div className="space-y-4">
          <div className="flex items-center gap-4">
            <input
              type="range"
              min="0"
              max="1"
              step="0.01"
              value={time}
              onChange={(e) => setTime(parseFloat(e.target.value))}
              className="w-full"
            />
            <span className="w-20 text-right">t = {time.toFixed(2)}</span>
          </div>

          <div
            className="w-full h-24 rounded-lg"
            style={{ backgroundColor: colorString }}
          />

          <div className="grid grid-cols-1 gap-4 text-sm">
            <div>
              Current RGB:
              <pre className="mt-1 p-2 bg-gray-100 text-black rounded">
                r: {currentColor.r} &nbsp; g: {currentColor.g} &nbsp; b:{" "}
                {currentColor.b}
              </pre>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
