const Support = () => {
  return (
    <div className="min-h-screen bg-gradient-to-b from-highlander-50 to-white dark:from-gray-900 dark:to-gray-800 text-gray-800 dark:text-gray-100">
      <div className="max-w-3xl mx-auto px-6 py-16 space-y-8">
        <header className="space-y-2">
          <h1 className="text-3xl font-bold text-highlander-800 dark:text-white">Support</h1>
          <p className="text-sm text-gray-500 dark:text-gray-400">We typically respond within 1–2 business days.</p>
        </header>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold">Contact</h2>
          <p>
            Email us at{" "}
            <a className="text-highlander-600 hover:underline" href="mailto:highlanderhomes22@gmail.com">
              highlanderhomes22@gmail.com
            </a>
            .
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold">Common Help</h2>
          <ul className="list-disc pl-5 space-y-2">
            <li>Subscription and billing questions</li>
            <li>Account access and password reset</li>
            <li>Data import and setup assistance</li>
            <li>Bug reports and feature requests</li>
          </ul>
        </section>
      </div>
    </div>
  );
};

export default Support;
