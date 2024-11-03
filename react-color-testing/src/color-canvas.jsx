import { useEffect, useRef } from "react";
import { calculateColor } from "./color-calculator";

export const ColorCanvas = () => {
  const canvasRef = useRef(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    const width = canvas.width;
    const height = canvas.height;
    const ctx = canvas.getContext("2d");
    ctx.clearRect(0, 0, width, height);

    // <https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createImageData>
    const imageData = ctx.createImageData(width, height);

    for (let i = 0; i < width; i++) {
      const { r, g, b } = calculateColor(i / (width - 1));
      for (let j = 0; j < height; j++) {
        const index = (i + j * width) * 4;
        imageData.data[index + 0] = r; // Red at index
        imageData.data[index + 1] = g; // Green at index+1
        imageData.data[index + 2] = b; // Blue at index+2
        imageData.data[index + 3] = 255; // Alpha at index+3 (fully opaque)
      }
    }
    ctx.putImageData(imageData, 0, 0);
  }, []);

  return (
    <div className="w-full max-w-2xl">
      <div className="relative">
        <canvas
          ref={canvasRef}
          width={400}
          height={400}
          className="border border-gray-300"
        />

        {/* X-axis labels */}
        <div className="absolute w-full -bottom-6 flex justify-between">
          <span className="text-sm">0.0</span>
          <span className="text-sm">0.5</span>
          <span className="text-sm">1.0</span>
        </div>
      </div>
    </div>
  );
};
