import * as React from "react"

import { cn } from "@/lib/utils"

// Converted to JS: define prop types via JSDoc instead of TS interface
/** @typedef {React.TextareaHTMLAttributes<HTMLTextAreaElement>} TextareaProps */

/** @type {React.ForwardRefExoticComponent<React.PropsWithoutRef<React.TextareaHTMLAttributes<HTMLTextAreaElement>> & React.RefAttributes<HTMLTextAreaElement>>} */
const Textarea = React.forwardRef((
  /** @type {TextareaProps} */ { className, ...props },
  /** @type {React.Ref<HTMLTextAreaElement>} */ ref
) => {
  return (
    <textarea
      className={cn(
        "flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50",
        className
      )}
      ref={ref}
      {...props}
    />
  )
})
Textarea.displayName = "Textarea"

export { Textarea }
