import React, { useState } from 'react';
import { cn } from '@/lib/utils';

export function TouchableButton({ 
  children, 
  className, 
  onClick, 
  variant = 'default',
  size = 'default',
  ...props 
}) {
  const [isPressed, setIsPressed] = useState(false);

  const handleTouchStart = () => {
    setIsPressed(true);
  };

  const handleTouchEnd = () => {
    setIsPressed(false);
  };

  const baseClasses = "inline-flex items-center justify-center rounded-md text-sm font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 touch-manipulation";
  
  const variantClasses = {
    default: "bg-primary text-primary-foreground hover:bg-primary/90 active:bg-primary/80",
    destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/90 active:bg-destructive/80",
    outline: "border border-input bg-background hover:bg-accent hover:text-accent-foreground active:bg-accent/80",
    secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80 active:bg-secondary/70",
    ghost: "hover:bg-accent hover:text-accent-foreground active:bg-accent/80",
    link: "text-primary underline-offset-4 hover:underline"
  };

  const sizeClasses = {
    default: "h-12 px-4 py-2 min-h-[48px]", // 48px minimum for accessibility
    sm: "h-10 rounded-md px-3 min-h-[44px]",
    lg: "h-14 rounded-md px-8 min-h-[56px]",
    icon: "h-12 w-12 min-h-[48px] min-w-[48px]"
  };

  return (
    <button
      className={cn(
        baseClasses,
        variantClasses[variant],
        sizeClasses[size],
        isPressed && "scale-95",
        className
      )}
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}
      onMouseDown={handleTouchStart}
      onMouseUp={handleTouchEnd}
      onMouseLeave={handleTouchEnd}
      onClick={onClick}
      {...props}
    >
      {children}
    </button>
  );
}

export function TouchableCard({ 
  children, 
  className, 
  onClick, 
  hoverable = true,
  ...props 
}) {
  const [isPressed, setIsPressed] = useState(false);

  const handleTouchStart = () => {
    if (onClick) setIsPressed(true);
  };

  const handleTouchEnd = () => {
    setIsPressed(false);
  };

  return (
    <div
      className={cn(
        "rounded-lg border bg-card text-card-foreground shadow-sm transition-all touch-manipulation",
        onClick && "cursor-pointer",
        hoverable && "hover:shadow-md",
        isPressed && "scale-[0.98] shadow-sm",
        className
      )}
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}
      onMouseDown={handleTouchStart}
      onMouseUp={handleTouchEnd}
      onMouseLeave={handleTouchEnd}
      onClick={onClick}
      {...props}
    >
      {children}
    </div>
  );
}

export function TouchableInput({
  className,
  ...props
}) {
  return (
    <input
      className={cn(
        "flex h-12 w-full rounded-md border border-input bg-background px-3 py-2 text-base ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 touch-manipulation",
        "min-h-[48px]", // Accessibility minimum
        className
      )}
      {...props}
    />
  );
}

export function MobileGrid({ children, className, ...props }) {
  return (
    <div
      className={cn(
        "grid gap-3 sm:gap-4 md:gap-6",
        "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4",
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
}

export function MobileStack({ children, className, spacing = 'default', ...props }) {
  const spacingClasses = {
    tight: "space-y-2",
    default: "space-y-4",
    loose: "space-y-6",
    extraLoose: "space-y-8"
  };

  return (
    <div
      className={cn(
        "flex flex-col w-full",
        spacingClasses[spacing],
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
}