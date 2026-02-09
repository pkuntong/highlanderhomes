const Privacy = () => {
  return (
    <div className="min-h-screen bg-gradient-to-b from-highlander-50 to-white dark:from-gray-900 dark:to-gray-800 text-gray-800 dark:text-gray-100">
      <div className="max-w-3xl mx-auto px-6 py-16 space-y-8">
        <header className="space-y-2">
          <h1 className="text-3xl font-bold text-highlander-800 dark:text-white">Privacy Policy</h1>
          <p className="text-sm text-gray-500 dark:text-gray-400">Effective date: February 9, 2026</p>
        </header>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold">1. Information We Collect</h2>
          <p>
            We collect information you provide directly, such as account details and property data. We may also collect usage information
            to improve the service.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold">2. How We Use Information</h2>
          <p>
            We use your information to provide, maintain, and improve Highlander Homes, including account authentication and customer support.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold">3. Sharing</h2>
          <p>
            We do not sell your personal information. We may share information with service providers strictly to operate the service.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold">4. Data Security</h2>
          <p>
            We take reasonable measures to protect your information. No system is 100% secure, and we cannot guarantee absolute security.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold">5. Contact</h2>
          <p>
            Questions about privacy? Email us at{" "}
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

export default Privacy;
