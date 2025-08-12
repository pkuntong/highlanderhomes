import * as React from "react"
import { cva } from "class-variance-authority"
import { cn } from "@/lib/utils"

// Premium Spinner Component
const spinnerVariants = cva(
  "animate-spin rounded-full border-solid border-r-transparent",
  {
    variants: {
      variant: {
        default: "border-primary border-2",
        secondary: "border-secondary border-2",
        accent: "border-accent-rose border-2",
        premium: "border-gradient-to-r from-primary to-accent-rose border-3",
        glass: "border-white/30 border-2 backdrop-blur-sm",
      },
      size: {
        sm: "h-4 w-4",
        default: "h-6 w-6",
        lg: "h-8 w-8",
        xl: "h-12 w-12",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

const Spinner = React.forwardRef(({ className, variant, size, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(spinnerVariants({ variant, size }), className)}
    {...props}
  />
))
Spinner.displayName = "Spinner"

// Premium Loading Dots
const LoadingDots = ({ className, variant = "default" }) => {
  const dotVariants = {
    default: "bg-primary",
    secondary: "bg-secondary",
    accent: "bg-accent-rose",
  }

  return (
    <div className={cn("flex space-x-1", className)}>
      {[0, 1, 2].map((i) => (
        <div
          key={i}
          className={cn(
            "h-2 w-2 rounded-full animate-bounce",
            dotVariants[variant]
          )}
          style={{
            animationDelay: `${i * 0.1}s`,
            animationDuration: "0.6s"
          }}
        />
      ))}
    </div>
  )
}

// Pulse Loading Animation
const PulseLoader = ({ className, variant = "default" }) => {
  const pulseVariants = {
    default: "bg-primary/20",
    secondary: "bg-secondary/20",
    accent: "bg-accent-rose/20",
  }

  return (
    <div className={cn("flex space-x-2", className)}>
      {[0, 1, 2].map((i) => (
        <div
          key={i}
          className={cn(
            "h-3 w-3 rounded-full animate-pulse",
            pulseVariants[variant]
          )}
          style={{
            animationDelay: `${i * 0.15}s`,
          }}
        />
      ))}
    </div>
  )
}

// Skeleton Components
const Skeleton = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      "loading-shimmer rounded-md bg-muted animate-pulse",
      className
    )}
    {...props}
  />
))
Skeleton.displayName = "Skeleton"

// Card Skeleton
const CardSkeleton = ({ className }) => (
  <div className={cn("card-premium p-6 space-y-4", className)}>
    <div className="flex items-center space-x-4">
      <Skeleton className="h-12 w-12 rounded-full" />
      <div className="space-y-2">
        <Skeleton className="h-4 w-32" />
        <Skeleton className="h-3 w-24" />
      </div>
    </div>
    <Skeleton className="h-20 w-full" />
    <div className="flex space-x-2">
      <Skeleton className="h-8 w-16" />
      <Skeleton className="h-8 w-20" />
    </div>
  </div>
)

// Table Skeleton
const TableSkeleton = ({ rows = 5, columns = 4, className }) => (
  <div className={cn("space-y-3", className)}>
    {/* Header */}
    <div className="flex space-x-4 p-4 border-b">
      {Array.from({ length: columns }).map((_, i) => (
        <Skeleton key={i} className="h-4 flex-1" />
      ))}
    </div>
    {/* Rows */}
    {Array.from({ length: rows }).map((_, rowIndex) => (
      <div key={rowIndex} className="flex space-x-4 p-4">
        {Array.from({ length: columns }).map((_, colIndex) => (
          <Skeleton key={colIndex} className="h-4 flex-1" />
        ))}
      </div>
    ))}
  </div>
)

// Dashboard Skeleton
const DashboardSkeleton = ({ className }) => (
  <div className={cn("space-y-6", className)}>
    {/* Stats Cards */}
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      {Array.from({ length: 4 }).map((_, i) => (
        <div key={i} className="card-premium p-6">
          <div className="flex items-center justify-between">
            <div className="space-y-2">
              <Skeleton className="h-3 w-20" />
              <Skeleton className="h-6 w-16" />
            </div>
            <Skeleton className="h-12 w-12 rounded-xl" />
          </div>
        </div>
      ))}
    </div>
    
    {/* Main Content */}
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div className="lg:col-span-2 space-y-4">
        <Skeleton className="h-6 w-32" />
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <CardSkeleton key={i} />
          ))}
        </div>
      </div>
      <div className="space-y-4">
        <Skeleton className="h-6 w-28" />
        <div className="card-premium p-6 space-y-4">
          {Array.from({ length: 5 }).map((_, i) => (
            <div key={i} className="flex items-center space-x-3">
              <Skeleton className="h-8 w-8 rounded-full" />
              <div className="space-y-1 flex-1">
                <Skeleton className="h-3 w-full" />
                <Skeleton className="h-2 w-2/3" />
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  </div>
)

// Premium Loading Overlay
const LoadingOverlay = ({ 
  isLoading, 
  children, 
  spinner = "default",
  text = "Loading...",
  className 
}) => {
  if (!isLoading) return children

  return (
    <div className={cn("relative", className)}>
      {children}
      <div className="absolute inset-0 bg-background/80 backdrop-blur-sm flex items-center justify-center z-50 rounded-xl">
        <div className="glass p-8 rounded-2xl flex flex-col items-center space-y-4">
          {spinner === "dots" ? (
            <LoadingDots variant="accent" />
          ) : spinner === "pulse" ? (
            <PulseLoader variant="accent" />
          ) : (
            <Spinner variant="premium" size="lg" />
          )}
          <p className="text-sm font-medium text-foreground-muted">{text}</p>
        </div>
      </div>
    </div>
  )
}

// Page Loading Component
const PageLoader = ({ text = "Loading page..." }) => (
  <div className="min-h-screen bg-premium flex items-center justify-center">
    <div className="glass p-12 rounded-3xl flex flex-col items-center space-y-6 max-w-md">
      <div className="relative">
        <Spinner variant="premium" size="xl" />
        <div className="absolute inset-0 animate-ping">
          <Spinner variant="glass" size="xl" />
        </div>
      </div>
      <div className="text-center space-y-2">
        <h3 className="text-lg font-semibold text-premium">Almost there</h3>
        <p className="text-sm text-foreground-muted">{text}</p>
      </div>
      <div className="w-32 h-1 bg-border rounded-full overflow-hidden">
        <div className="h-full bg-gradient-to-r from-primary to-accent-rose animate-gradient-x" />
      </div>
    </div>
  </div>
)

// Button Loading State
const LoadingButton = React.forwardRef(({ 
  children, 
  isLoading, 
  loadingText = "Loading...",
  variant = "default",
  className,
  disabled,
  ...props 
}, ref) => {
  return (
    <button
      ref={ref}
      disabled={disabled || isLoading}
      className={cn(
        "relative",
        className
      )}
      {...props}
    >
      {isLoading && (
        <div className="absolute inset-0 flex items-center justify-center">
          <Spinner size="sm" variant={variant === "default" ? "glass" : "default"} />
        </div>
      )}
      <span className={cn(
        "flex items-center justify-center gap-2",
        isLoading && "opacity-0"
      )}>
        {isLoading ? loadingText : children}
      </span>
    </button>
  )
})
LoadingButton.displayName = "LoadingButton"

export {
  Spinner,
  LoadingDots,
  PulseLoader,
  Skeleton,
  CardSkeleton,
  TableSkeleton,
  DashboardSkeleton,
  LoadingOverlay,
  PageLoader,
  LoadingButton,
  spinnerVariants,
}