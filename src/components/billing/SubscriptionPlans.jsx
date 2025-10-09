import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Check, Zap, Star, Crown } from "lucide-react";

export default function SubscriptionPlans({ currentPlan = "free", onSelectPlan }) {
  const plans = [
    {
      id: "free",
      name: "Free",
      price: 0,
      period: "forever",
      description: "Perfect for getting started",
      icon: Zap,
      features: [
        "Up to 5 properties",
        "Basic property management",
        "Tenant tracking",
        "Document storage (100MB)",
        "Email support"
      ],
      limits: "5 properties max"
    },
    {
      id: "pro",
      name: "Pro",
      price: 29,
      period: "month",
      description: "For growing portfolios",
      icon: Star,
      popular: true,
      features: [
        "Unlimited properties",
        "RentCast market data",
        "Payment tracking",
        "Advanced analytics",
        "Document storage (5GB)",
        "Priority support",
        "Export to PDF/CSV"
      ],
      limits: "No limits"
    },
    {
      id: "enterprise",
      name: "Enterprise",
      price: 99,
      period: "month",
      description: "For professional managers",
      icon: Crown,
      features: [
        "Everything in Pro",
        "Automated rent collection",
        "Bank integration (Plaid)",
        "Multi-user access",
        "White-label reports",
        "API access",
        "Document storage (50GB)",
        "Dedicated support"
      ],
      limits: "Custom solutions available"
    }
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
      {plans.map((plan) => {
        const Icon = plan.icon;
        const isCurrentPlan = currentPlan === plan.id;

        return (
          <Card key={plan.id} className={`relative ${plan.popular ? 'border-primary shadow-lg' : ''}`}>
            {plan.popular && (
              <Badge className="absolute -top-3 left-1/2 transform -translate-x-1/2">
                Most Popular
              </Badge>
            )}
            
            <CardHeader>
              <div className="flex items-center justify-between mb-2">
                <Icon className="h-8 w-8 text-primary" />
                {isCurrentPlan && (
                  <Badge variant="secondary">Current Plan</Badge>
                )}
              </div>
              <CardTitle className="text-2xl">{plan.name}</CardTitle>
              <CardDescription>{plan.description}</CardDescription>
            </CardHeader>

            <CardContent>
              <div className="mb-6">
                <div className="flex items-baseline">
                  <span className="text-4xl font-bold">${plan.price}</span>
                  <span className="text-muted-foreground ml-2">/{plan.period}</span>
                </div>
                <p className="text-sm text-muted-foreground mt-1">{plan.limits}</p>
              </div>

              <ul className="space-y-3">
                {plan.features.map((feature, index) => (
                  <li key={index} className="flex items-start">
                    <Check className="h-5 w-5 text-green-600 mr-2 flex-shrink-0 mt-0.5" />
                    <span className="text-sm">{feature}</span>
                  </li>
                ))}
              </ul>
            </CardContent>

            <CardFooter>
              <Button
                className="w-full"
                variant={isCurrentPlan ? "outline" : plan.popular ? "default" : "outline"}
                onClick={() => onSelectPlan && onSelectPlan(plan.id)}
                disabled={isCurrentPlan}
              >
                {isCurrentPlan ? "Current Plan" : `Choose ${plan.name}`}
              </Button>
            </CardFooter>
          </Card>
        );
      })}
    </div>
  );
}
