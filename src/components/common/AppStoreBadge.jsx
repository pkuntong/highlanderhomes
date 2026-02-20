import { cn } from "@/lib/utils";

export default function AppStoreBadge({ href, className }) {
  return (
    <a
      href={href}
      target="_blank"
      rel="noreferrer"
      aria-label="Download Highlander Homes on the App Store"
      className={cn(
        "inline-flex items-center gap-3 rounded-2xl bg-black px-4 py-2.5 text-white shadow-sm transition hover:bg-black/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-black focus-visible:ring-offset-2",
        className
      )}
    >
      <span aria-hidden className="text-3xl leading-none">
        
      </span>
      <span className="flex flex-col leading-none">
        <span className="text-[10px] uppercase tracking-[0.08em] text-white/80">
          Download on the
        </span>
        <span className="text-[26px] font-semibold tracking-tight">App Store</span>
      </span>
    </a>
  );
}
