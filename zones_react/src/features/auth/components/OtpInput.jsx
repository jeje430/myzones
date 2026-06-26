import { useRef } from "react";
import { cn } from "@/lib/utils";

export default function OtpInput({ value = "", onChange, disabled, onComplete }) {
  const inputsRef = useRef([]);
  const digits = Array.from({ length: 6 }, (_, i) => value[i] || "");

  const focusAt = (index) => {
    inputsRef.current[index]?.focus();
  };

  const applyCode = (code) => {
    const normalized = String(code).replace(/\D/g, "").slice(0, 6);
    onChange(normalized);
    if (normalized.length === 6) {
      onComplete?.(normalized);
    }
    return normalized;
  };

  const handleChange = (index, raw) => {
    const char = raw.replace(/\D/g, "").slice(-1);
    const next = [...digits];
    next[index] = char;
    const code = next.join("");
    applyCode(code);
    if (char && index < 5) focusAt(index + 1);
  };

  const handleKeyDown = (index, event) => {
    if (event.key === "Backspace") {
      if (digits[index]) {
        const next = [...digits];
        next[index] = "";
        onChange(next.join(""));
      } else if (index > 0) {
        focusAt(index - 1);
      }
    }
    if (event.key === "ArrowLeft" && index > 0) focusAt(index - 1);
    if (event.key === "ArrowRight" && index < 5) focusAt(index + 1);
  };

  const handlePaste = (event) => {
    event.preventDefault();
    const pasted = applyCode(event.clipboardData.getData("text"));
    focusAt(Math.min(pasted.length, 5));
  };

  return (
    <div className="flex items-center justify-center gap-2 sm:gap-2.5" dir="ltr">
      {digits.map((digit, index) => (
        <input
          key={index}
          ref={(el) => {
            inputsRef.current[index] = el;
          }}
          type="text"
          inputMode="numeric"
          pattern="[0-9]*"
          maxLength={1}
          value={digit}
          disabled={disabled}
          autoComplete="one-time-code"
          aria-label={`رمز التحقق ${index + 1}`}
          className={cn(
            "h-12 w-11 rounded-xl border text-center text-lg font-bold tracking-widest transition sm:h-14 sm:w-12 sm:text-xl",
            "border-gray-200 bg-gray-50 text-gray-900 dark:border-gray-700 dark:bg-gray-800/80 dark:text-white",
            "focus:border-[#6B5478] focus:outline-none focus:ring-2 focus:ring-[#6B5478]/30",
            disabled && "opacity-60",
          )}
          onChange={(e) => handleChange(index, e.target.value)}
          onKeyDown={(e) => handleKeyDown(index, e)}
          onPaste={handlePaste}
          onFocus={(e) => e.target.select()}
        />
      ))}
    </div>
  );
}
