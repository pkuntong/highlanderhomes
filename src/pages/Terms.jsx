const Terms = () => {
  return (
    <div className="min-h-screen bg-gradient-to-b from-highlander-50 to-white dark:from-gray-900 dark:to-gray-800 text-gray-800 dark:text-gray-100">
      <div className="max-w-3xl mx-auto px-6 py-16 space-y-8">
        <header className="space-y-2">
          <h1 className="text-3xl font-bold text-highlander-800 dark:text-white">Terms of Service</h1>
          <p className="text-sm text-gray-500 dark:text-gray-400">Effective date: February 9, 2026</p>
        </header>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold">1. Acceptance of Terms</h2>
          <p>
            By accessing or using Highlander Homes, you agree to these Terms of Service. If you do not agree, do not use the service.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold">2. Use of the Service</h2>
          <p>
            You agree to use the service only for lawful purposes and in compliance with all applicable laws and regulations.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold">3. Accounts</h2>
          <p>
            You are responsible for maintaining the confidentiality of your account credentials and for all activity under your account.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold">4. Subscription & Billing</h2>
          <p>
            Paid plans are billed on a recurring basis. You can cancel at any time and retain access through the end of the billing period.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold">5. Termination</h2>
          <p>
            We may suspend or terminate your access if you violate these terms or use the service in a harmful way.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold">6. Contact</h2>
          <p>
            Questions about these terms? Email us at{" "}
            <a className="text-highlander-600 hover:underline" href="mailto:highlanderhomes22@gmail.com">
              highlanderhomes22@gmail.com
            </a>
            .
          </p>
        </section>
      </div>
    </div>
  );
};

export default Terms;
