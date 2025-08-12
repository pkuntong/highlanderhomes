import { Card, CardContent } from "@/components/ui/card";
import { useState } from "react";

const StatCard = ({ title, value, icon, trend, trendUp }) => {
  const [isHovered, setIsHovered] = useState(false);

  return (
    <Card 
      className="card-premium group cursor-pointer border-0 bg-gradient-to-br from-background-elevated to-background-glass backdrop-blur-md overflow-hidden relative"
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      {/* Animated background gradient */}
      <div className="absolute inset-0 bg-gradient-to-br from-primary/5 via-accent-rose/5 to-accent-emerald/5 opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
      
      {/* Shimmer effect */}
      <div className="absolute inset-0 -translate-x-full bg-gradient-to-r from-transparent via-white/10 to-transparent group-hover:translate-x-full transition-transform duration-1000 ease-in-out" />
      
      <CardContent className="p-6 relative z-10">
        <div className="flex items-center justify-between">
          <div className="space-y-2">
            <p className="text-sm font-medium text-foreground-muted tracking-wide uppercase">
              {title}
            </p>
            <div className="space-y-1">
              <h2 className="text-3xl font-bold text-premium tracking-tight">
                {value}
              </h2>
              {trend && (
                <div className={`flex items-center text-sm font-medium ${
                  trendUp ? 'text-accent-emerald' : 'text-accent-rose'
                }`}>
                  <span className={`mr-1 ${trendUp ? '↗' : '↘'}`}>
                    {trendUp ? '↗' : '↘'}
                  </span>
                  {Math.abs(trend.value)}% {trend.label}
                </div>
              )}
            </div>
          </div>
          
          <div className={`relative p-4 rounded-2xl transition-all duration-300 ${
            isHovered 
              ? 'bg-primary shadow-glow scale-110 rotate-6' 
              : 'bg-gradient-to-br from-primary-50 to-primary-100 shadow-md'
          }`}>
            <div className={`transition-colors duration-300 ${
              isHovered ? 'text-primary-foreground' : 'text-primary'
            }`}>
              {icon}
            </div>
            
            {/* Animated ring on hover */}
            {isHovered && (
              <div className="absolute inset-0 rounded-2xl border-2 border-primary/30 animate-ping" />
            )}
          </div>
        </div>
        
        {/* Bottom accent line */}
        <div className="absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r from-primary via-accent-rose to-accent-emerald transform scale-x-0 group-hover:scale-x-100 transition-transform duration-500 ease-out" />
      </CardContent>
    </Card>
  );
};

export default StatCard;
