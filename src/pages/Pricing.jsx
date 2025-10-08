import { useState } from "react";
import { useNavigate } from "react-router-dom";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Check, Zap, Crown, Building } from "lucide-react";
import { PRICING_TIERS, redirectToCheckout } from "@/services/stripe";
import { useAuth } from "@/contexts/AuthContext";

export default function Pricing() {
  const [loading, setLoading] = useState(null);
  const navigate = useNavigate();
  const { user } = useAuth();

  const handleSelectPlan = async (tier) => {
    if (!user) {
      navigate('/login');
      return;
    }

    if (tier.id === 'free') {
      // Free tier - just update user's subscription in Firestore
      alert('You are already on the free plan!');
      return;
    }

    setLoading(tier.id);
    try {
      await redirectToCheckout(tier.priceId, user.email, user.uid);
    } catch (error) {
      console.error('Error selecting plan:', error);
      alert('Failed to process subscription. Please try again.');
    } finally {
      setLoading(null);
    }
  };

  const tiers = [
    {
      ...PRICING_TIERS.FREE,
      icon: Building,
      description: 'Perfect for getting started with property management',
      highlighted: false,
    },
    {
      ...PRICING_TIERS.PRO,
      icon: Zap,
      description: 'For growing property managers and small landlords',
      highlighted: true,
    },
    {
      ...PRICING_TIERS.ENTERPRISE,
      icon: Crown,
      description: 'For professional property management companies',
      highlighted: false,
    },
  ];

  return (
    <PageLayout title="Pricing">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold mb-4">
            Simple, Transparent Pricing
          </h1>
          <p className="text-xl text-muted-foreground">
            Choose the plan that's right for your business
          </p>
        </div>

        {/* Pricing Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
          {tiers.map((tier) => {
            const Icon = tier.icon;
            return (
              <Card
                key={tier.id}
                className={`relative ${
                  tier.highlighted
                    ? 'border-highlander-600 shadow-lg ring-2 ring-highlander-600'
                    : ''
                }`}
              >
                {tier.highlighted && (
                  <div className="absolute -top-4 left-1/2 transform -translate-x-1/2">
                    <Badge className="bg-highlander-600 text-white">
                      Most Popular
                    </Badge>
                  </div>
                )}

                <CardHeader>
                  <div className="flex items-center justify-between mb-2">
                    <Icon className="h-8 w-8 text-highlander-600" />
                    {tier.id === 'pro' && (
                      <Badge variant="secondary">Best Value</Badge>
                    )}
                  </div>
                  <CardTitle className="text-2xl">{tier.name}</CardTitle>
                  <CardDescription>{tier.description}</CardDescription>
                </CardHeader>

                <CardContent className="space-y-6">
                  {/* Price */}
                  <div className="flex items-baseline gap-2">
                    <span className="text-5xl font-bold">
                      ${tier.price}
                    </span>
                    <span className="text-muted-foreground">
                      /{tier.interval}
                    </span>
                  </div>

                  {/* Features */}
                  <ul className="space-y-3">
                    {tier.features.map((feature, index) => (
                      <li key={index} className="flex items-start gap-2">
                        <Check className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
                        <span className="text-sm">{feature}</span>
                      </li>
                    ))}
                  </ul>

                  {/* Limits */}
                  <div className="pt-4 border-t space-y-2">
                    <div className="flex justify-between text-sm">
                      <span className="text-muted-foreground">Properties:</span>
                      <span className="font-medium">
                        {tier.limits.properties === Infinity
                          ? 'Unlimited'
                          : `Up to ${tier.limits.properties}`}
                      </span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-muted-foreground">Documents:</span>
                      <span className="font-medium">
                        {tier.limits.documents === Infinity
                          ? 'Unlimited'
                          : `Up to ${tier.limits.documents}`}
                      </span>
                    </div>
                  </div>
                </CardContent>

                <CardFooter>
                  <Button
                    className="w-full"
                    variant={tier.highlighted ? 'default' : 'outline'}
                    size="lg"
                    onClick={() => handleSelectPlan(tier)}
                    disabled={loading === tier.id}
                  >
                    {loading === tier.id ? (
                      'Processing...'
                    ) : tier.id === 'free' ? (
                      'Current Plan'
                    ) : (
                      `Choose ${tier.name}`
                    )}
                  </Button>
                </CardFooter>
              </Card>
            );
          })}
        </div>

        {/* FAQ Section */}
        <div className="mt-16">
          <h2 className="text-2xl font-bold text-center mb-8">
            Frequently Asked Questions
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-4xl mx-auto">
            <div>
              <h3 className="font-semibold mb-2">Can I change plans later?</h3>
              <p className="text-sm text-muted-foreground">
                Yes! You can upgrade or downgrade your plan at any time. Changes are prorated.
              </p>
            </div>
            <div>
              <h3 className="font-semibold mb-2">What payment methods do you accept?</h3>
              <p className="text-sm text-muted-foreground">
                We accept all major credit cards through Stripe's secure payment processing.
              </p>
            </div>
            <div>
              <h3 className="font-semibold mb-2">Is there a contract?</h3>
              <p className="text-sm text-muted-foreground">
                No contracts! All plans are month-to-month. Cancel anytime.
              </p>
            </div>
            <div>
              <h3 className="font-semibold mb-2">Do you offer refunds?</h3>
              <p className="text-sm text-muted-foreground">
                We offer a 14-day money-back guarantee for all paid plans.
              </p>
            </div>
          </div>
        </div>

        {/* Backend Notice */}
        <div className="mt-12 p-6 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
          <h3 className="font-semibold mb-2 text-yellow-900 dark:text-yellow-100">
            ⚠️ Backend Required for Payments
          </h3>
          <p className="text-sm text-yellow-800 dark:text-yellow-200">
            To enable subscriptions, you need to set up backend endpoints for Stripe. See{' '}
            <code className="bg-yellow-200 dark:bg-yellow-800 px-1 rounded">docs/STRIPE_SETUP.md</code>{' '}
            for instructions on creating checkout sessions and handling webhooks.
          </p>
        </div>
      </div>
    </PageLayout>
  );
}
