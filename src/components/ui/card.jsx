import * as React from "react"
import { cva } from "class-variance-authority"

import { cn } from "@/lib/utils"

const cardVariants = cva(
  "rounded-xl border bg-card text-card-foreground transition-all duration-300 ease-out relative overflow-hidden group",
  {
    variants: {
      variant: {
        default: "shadow-md hover:shadow-elevated border-border",
        premium: "shadow-premium hover:shadow-glow border-border-subtle backdrop-blur-sm",
        glass: "glass border-border-subtle backdrop-blur-premium",
        elevated: "shadow-elevated hover:shadow-premium border-0 bg-background-elevated",
        interactive: "shadow-md hover:shadow-premium hover:-translate-y-2 cursor-pointer border-border hover:border-primary/30",
      },
      padding: {
        default: "p-6",
        sm: "p-4",
        lg: "p-8",
        none: "p-0",
      }
    },
    defaultVariants: {
      variant: "default",
      padding: "default"
    }
  }
)

const Card = React.forwardRef(({ className, variant, padding, children, ...props }, ref) => {
  const [isHovered, setIsHovered] = React.useState(false);
  
  return (
    <div 
      ref={ref} 
      className={cn(cardVariants({ variant, padding }), className)} 
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      {...props}
    >
      {/* Animated background gradient */}
      {variant === "premium" && (
        <div className="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-accent-rose/5 opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
      )}
      
      {/* Shimmer effect for interactive cards */}
      {variant === "interactive" && (
        <div className="absolute inset-0 -translate-x-full bg-gradient-to-r from-transparent via-white/10 to-transparent group-hover:translate-x-full transition-transform duration-1000 ease-in-out" />
      )}
      
      {/* Content */}
      <div className="relative z-10">
        {children}
      </div>
      
      {/* Bottom accent line for premium cards */}
      {variant === "premium" && isHovered && (
        <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-primary via-accent-rose to-accent-emerald animate-slide-up" />
      )}
    </div>
  )
})
Card.displayName = "Card"

const CardHeader = React.forwardRef(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("flex flex-col space-y-2 p-6", className)} {...props} />
))
CardHeader.displayName = "CardHeader"

const CardTitle = React.forwardRef(({ className, ...props }, ref) => (
  <h3 ref={ref} className={cn("text-2xl font-bold leading-tight tracking-tight text-premium", className)} {...props} />
))
CardTitle.displayName = "CardTitle"

const CardDescription = React.forwardRef(({ className, ...props }, ref) => (
  <p ref={ref} className={cn("text-sm text-foreground-muted leading-relaxed", className)} {...props} />
))
CardDescription.displayName = "CardDescription"

const CardContent = React.forwardRef(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("p-6 pt-0", className)} {...props} />
))
CardContent.displayName = "CardContent"

const CardFooter = React.forwardRef(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("flex items-center p-6 pt-0", className)} {...props} />
))
CardFooter.displayName = "CardFooter"

// Premium card variants for specific use cases
const PremiumCard = React.forwardRef(({ className, children, ...props }, ref) => (
  <Card ref={ref} variant="premium" className={className} {...props}>
    {children}
  </Card>
))
PremiumCard.displayName = "PremiumCard"

const GlassCard = React.forwardRef(({ className, children, ...props }, ref) => (
  <Card ref={ref} variant="glass" className={className} {...props}>
    {children}
  </Card>
))
GlassCard.displayName = "GlassCard"

const InteractiveCard = React.forwardRef(({ className, children, ...props }, ref) => (
  <Card ref={ref} variant="interactive" className={className} {...props}>
    {children}
  </Card>
))
InteractiveCard.displayName = "InteractiveCard"

export { 
  Card, 
  CardHeader, 
  CardFooter, 
  CardTitle, 
  CardDescription, 
  CardContent,
  PremiumCard,
  GlassCard,
  InteractiveCard,
  cardVariants
}
