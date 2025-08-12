import * as React from "react"
import { cva } from "class-variance-authority"

import { cn } from "@/lib/utils"

const inputVariants = cva(
  "flex w-full rounded-xl border bg-background text-sm transition-all duration-300 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-foreground-muted disabled:cursor-not-allowed disabled:opacity-50 focus-premium",
  {
    variants: {
      variant: {
        default:
          "h-11 border-border px-4 py-3 shadow-sm hover:shadow-md focus:border-primary focus:shadow-elevated",
        premium:
          "h-12 border-2 border-border-subtle px-4 py-3 shadow-md backdrop-blur-sm hover:shadow-elevated focus:border-primary focus:shadow-premium focus:scale-[1.02]",
        glass:
          "h-11 glass border-border-subtle px-4 py-3 backdrop-blur-premium focus:border-primary/50",
        floating:
          "h-14 border-2 border-border px-4 pt-6 pb-2 shadow-md focus:border-primary focus:shadow-premium",
      },
      size: {
        default: "h-11",
        sm: "h-9 text-xs",
        lg: "h-14 text-base",
      }
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

const Input = React.forwardRef(({ className, type, variant, size, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(inputVariants({ variant, size }), className)}
        ref={ref}
        {...props}
      />
    )
})
Input.displayName = "Input"

// Floating Label Input Component
const FloatingLabelInput = React.forwardRef(({ className, label, id, ...props }, ref) => {
  const [isFocused, setIsFocused] = React.useState(false);
  const [hasValue, setHasValue] = React.useState(false);
  
  const handleFocus = () => setIsFocused(true);
  const handleBlur = (e) => {
    setIsFocused(false);
    setHasValue(!!e.target.value);
  };
  
  return (
    <div className="relative">
      <Input
        ref={ref}
        id={id}
        variant="floating"
        className={cn("peer", className)}
        onFocus={handleFocus}
        onBlur={handleBlur}
        onChange={(e) => setHasValue(!!e.target.value)}
        placeholder=" "
        {...props}
      />
      <label
        htmlFor={id}
        className={cn(
          "absolute left-4 text-foreground-muted transition-all duration-300 pointer-events-none",
          "peer-placeholder-shown:top-4 peer-placeholder-shown:text-base peer-placeholder-shown:text-foreground-muted",
          "peer-focus:top-2 peer-focus:text-xs peer-focus:text-primary peer-focus:font-medium",
          (isFocused || hasValue) && "top-2 text-xs text-primary font-medium"
        )}
      >
        {label}
      </label>
    </div>
  );
});
FloatingLabelInput.displayName = "FloatingLabelInput";

// Premium Search Input with Icon
const SearchInput = React.forwardRef(({ className, icon, ...props }, ref) => {
  return (
    <div className="relative">
      {icon && (
        <div className="absolute left-3 top-1/2 transform -translate-y-1/2 text-foreground-muted">
          {icon}
        </div>
      )}
      <Input
        ref={ref}
        variant="premium"
        className={cn(
          icon ? "pl-10" : "pl-4",
          "focus:pl-4 transition-all duration-300",
          className
        )}
        {...props}
      />
    </div>
  );
});
SearchInput.displayName = "SearchInput";

// Animated Input with Success/Error States
const StatefulInput = React.forwardRef(({ 
  className, 
  state = "default", 
  message,
  icon,
  ...props 
}, ref) => {
  const stateStyles = {
    default: "border-border focus:border-primary",
    success: "border-accent-emerald bg-accent-emerald/5 focus:border-accent-emerald",
    error: "border-destructive bg-destructive/5 focus:border-destructive",
    warning: "border-accent-gold bg-accent-gold/5 focus:border-accent-gold"
  };
  
  const stateIcons = {
    success: "✓",
    error: "✕",
    warning: "⚠"
  };
  
  return (
    <div className="space-y-2">
      <div className="relative">
        <Input
          ref={ref}
          variant="premium"
          className={cn(
            stateStyles[state],
            state !== "default" && "pr-10",
            className
          )}
          {...props}
        />
        {state !== "default" && (
          <div className={cn(
            "absolute right-3 top-1/2 transform -translate-y-1/2 text-sm font-medium",
            state === "success" && "text-accent-emerald",
            state === "error" && "text-destructive",
            state === "warning" && "text-accent-gold"
          )}>
            {stateIcons[state]}
          </div>
        )}
      </div>
      {message && (
        <p className={cn(
          "text-xs font-medium animate-slide-down",
          state === "success" && "text-accent-emerald",
          state === "error" && "text-destructive",
          state === "warning" && "text-accent-gold",
          state === "default" && "text-foreground-muted"
        )}>
          {message}
        </p>
      )}
    </div>
  );
});
StatefulInput.displayName = "StatefulInput";

export { 
  Input, 
  FloatingLabelInput, 
  SearchInput, 
  StatefulInput,
  inputVariants 
}
