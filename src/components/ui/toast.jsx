import * as React from "react"
import * as ToastPrimitives from "@radix-ui/react-toast"
import { cva } from "class-variance-authority"
import { X } from "lucide-react"

import { cn } from "@/lib/utils"

const ToastProvider = ToastPrimitives.Provider

const ToastViewport = React.forwardRef(({ className, ...props }, ref) => (
  <ToastPrimitives.Viewport
    ref={ref}
    className={cn(
      "fixed top-0 z-[100] flex max-h-screen w-full flex-col-reverse p-6 sm:bottom-0 sm:right-0 sm:top-auto sm:flex-col md:max-w-[480px]",
      className
    )}
    {...props}
  />
))
ToastViewport.displayName = ToastPrimitives.Viewport.displayName

const toastVariants = cva(
  "group pointer-events-auto relative flex w-full items-start justify-between space-x-4 overflow-hidden rounded-2xl border backdrop-blur-premium p-6 pr-10 shadow-premium transition-all duration-300 data-[swipe=cancel]:translate-x-0 data-[swipe=end]:translate-x-[var(--radix-toast-swipe-end-x)] data-[swipe=move]:translate-x-[var(--radix-toast-swipe-move-x)] data-[swipe=move]:transition-none data-[state=open]:animate-in data-[state=closed]:animate-out data-[swipe=end]:animate-out data-[state=closed]:fade-out-80 data-[state=closed]:slide-out-to-right-full data-[state=open]:slide-in-from-top-full data-[state=open]:sm:slide-in-from-bottom-full data-[state=open]:animate-scale-in",
  {
    variants: {
      variant: {
        default: "border-border-subtle bg-background-elevated/90 text-foreground",
        success: "border-accent-emerald/30 bg-accent-emerald/10 text-accent-emerald backdrop-blur-premium",
        destructive: "border-destructive/30 bg-destructive/10 text-destructive backdrop-blur-premium",
        warning: "border-accent-gold/30 bg-accent-gold/10 text-accent-gold backdrop-blur-premium",
        info: "border-primary/30 bg-primary/10 text-primary backdrop-blur-premium",
        premium: "glass border-border-subtle bg-gradient-to-br from-background-elevated/90 to-background-glass text-foreground",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
)

const Toast = React.forwardRef(({ className, variant, ...props }, ref) => {
  return (
    <ToastPrimitives.Root
      ref={ref}
      className={cn(toastVariants({ variant }), className)}
      {...props}
    />
  )
})
Toast.displayName = ToastPrimitives.Root.displayName

const ToastAction = React.forwardRef(({ className, ...props }, ref) => (
  <ToastPrimitives.Action
    ref={ref}
    className={cn(
      "inline-flex h-9 shrink-0 items-center justify-center rounded-xl border bg-background/50 px-4 text-sm font-medium backdrop-blur-sm transition-all duration-300 hover:bg-background hover:scale-105 focus-premium disabled:pointer-events-none disabled:opacity-50",
      className
    )}
    {...props}
  />
))
ToastAction.displayName = ToastPrimitives.Action.displayName

const ToastClose = React.forwardRef(({ className, ...props }, ref) => (
  <ToastPrimitives.Close
    ref={ref}
    className={cn(
      "absolute right-3 top-3 rounded-lg p-1.5 text-foreground/60 opacity-0 transition-all duration-300 hover:text-foreground hover:bg-background/50 hover:scale-110 focus:opacity-100 focus-premium group-hover:opacity-100",
      className
    )}
    toast-close=""
    {...props}
  >
    <X className="h-4 w-4" />
  </ToastPrimitives.Close>
))
ToastClose.displayName = ToastPrimitives.Close.displayName

const ToastTitle = React.forwardRef(({ className, ...props }, ref) => (
  <ToastPrimitives.Title
    ref={ref}
    className={cn("text-base font-bold tracking-tight", className)}
    {...props}
  />
))
ToastTitle.displayName = ToastPrimitives.Title.displayName

const ToastDescription = React.forwardRef(({ className, ...props }, ref) => (
  <ToastPrimitives.Description
    ref={ref}
    className={cn("text-sm opacity-80 leading-relaxed mt-1", className)}
    {...props}
  />
))
ToastDescription.displayName = ToastPrimitives.Description.displayName

// Premium Toast Icon Component
const ToastIcon = ({ variant, className }) => {
  const icons = {
    success: "✓",
    destructive: "✕",
    warning: "⚠",
    info: "ℹ",
    default: "●",
    premium: "★"
  };

  const iconColors = {
    success: "text-accent-emerald",
    destructive: "text-destructive",
    warning: "text-accent-gold",
    info: "text-primary",
    default: "text-foreground-muted",
    premium: "text-primary"
  };

  return (
    <div className={cn(
      "flex items-center justify-center w-8 h-8 rounded-full font-bold text-lg mr-2 flex-shrink-0",
      iconColors[variant] || iconColors.default,
      className
    )}>
      {icons[variant] || icons.default}
    </div>
  );
};

export {
  ToastProvider,
  ToastViewport,
  Toast,
  ToastTitle,
  ToastDescription,
  ToastClose,
  ToastAction,
  ToastIcon,
  toastVariants,
}
