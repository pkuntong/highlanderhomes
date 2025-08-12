import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva } from "class-variance-authority"

import { cn } from "@/lib/utils"

const buttonVariants = cva(
  "relative inline-flex items-center justify-center whitespace-nowrap rounded-xl text-sm font-semibold transition-all duration-300 focus-premium disabled:pointer-events-none disabled:opacity-50 overflow-hidden tracking-tight",
  {
    variants: {
      variant: {
        default:
          "bg-gradient-to-r from-primary to-primary-600 text-primary-foreground shadow-premium hover:shadow-glow hover:scale-105 active:scale-95",
        destructive:
          "bg-gradient-to-r from-destructive to-red-600 text-destructive-foreground shadow-lg hover:shadow-red-500/25 hover:scale-105 active:scale-95",
        outline:
          "border-2 border-border bg-background/50 backdrop-blur-sm shadow-md hover:bg-accent-premium hover:border-primary hover:shadow-elevated hover:scale-105 active:scale-95",
        secondary:
          "bg-gradient-to-r from-secondary to-secondary-hover text-secondary-foreground shadow-md hover:shadow-elevated hover:scale-105 active:scale-95",
        ghost: 
          "hover:bg-accent-premium hover:shadow-md hover:scale-105 active:scale-95 backdrop-blur-sm",
        link: 
          "text-primary underline-offset-4 hover:underline hover:text-primary-600 transition-colors",
        premium:
          "bg-gradient-to-r from-accent-gold to-yellow-500 text-white shadow-premium hover:shadow-glow-lg hover:scale-105 active:scale-95 font-bold",
        glass:
          "glass backdrop-blur-premium hover:shadow-glass hover:scale-105 active:scale-95",
      },
      size: {
        default: "h-11 px-6 py-3",
        sm: "h-9 rounded-lg px-4 text-xs",
        lg: "h-14 rounded-2xl px-10 text-base",
        icon: "h-11 w-11",
        xl: "h-16 rounded-2xl px-12 text-lg",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

const Button = React.forwardRef(({ className, variant, size, asChild = false, children, ...props }, ref) => {
  const [ripples, setRipples] = React.useState([])

  // When asChild is true, we must render a single child element only.
  if (asChild) {
    return (
      <Slot
        className={cn(buttonVariants({ variant, size }), className)}
        ref={ref}
        {...props}
      >
        {children}
      </Slot>
    )
  }

  const handleClick = (event) => {
    const button = event.currentTarget
    const rect = button.getBoundingClientRect()
    const sizePx = Math.max(rect.width, rect.height)
    const x = event.clientX - rect.left - sizePx / 2
    const y = event.clientY - rect.top - sizePx / 2

    const newRipple = { x, y, size: sizePx, id: Date.now() }
    setRipples((prev) => [...prev, newRipple])

    setTimeout(() => {
      setRipples((prev) => prev.filter((ripple) => ripple.id !== newRipple.id))
    }, 600)

    if (props.onClick) props.onClick(event)
  }

  return (
    <button
      className={cn(buttonVariants({ variant, size }), className)}
      ref={ref}
      onClick={handleClick}
      {...props}
    >
      <div className="absolute inset-0 -translate-x-full bg-gradient-to-r from-transparent via-white/20 to-transparent group-hover:translate-x-full transition-transform duration-700 ease-in-out" />
      {ripples.map((ripple) => (
        <span
          key={ripple.id}
          className="absolute bg-white/30 rounded-full animate-ripple pointer-events-none"
          style={{ left: ripple.x, top: ripple.y, width: ripple.size, height: ripple.size }}
        />
      ))}
      <span className="relative z-10 flex items-center justify-center gap-2">{children}</span>
    </button>
  )
})
Button.displayName = "Button"

export { Button, buttonVariants }
