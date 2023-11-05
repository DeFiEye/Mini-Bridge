import React from "react";
import { createRoot } from "react-dom/client";
import { Provider } from "jotai";
import { WagmiConfig } from "wagmi";
import {
  QueryCache,
  QueryClient,
  QueryClientProvider,
} from "@tanstack/react-query";
import { ReactQueryDevtools } from "@tanstack/react-query-devtools";
import { message } from "antd";
import "antd/es/message/style";
import "./assets/css/reset.scss";
import "./assets/css/custom.scss";
import "./assets/css/theme/dark.scss";
import "./assets/css/theme/light.scss";
import "uno.css";
import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import zt from "../src/assets/language/zt.json";
import en from "../src/assets/language/en.json";
import { wagmiConfig } from "./wagmi";
import AppRouter from "./router";

// Sentry.init({
//   dsn: "https://7ae3dee92e7343eda79973bdd70ad1bf@o1277160.ingest.sentry.io/6474516",
//   integrations: [new BrowserTracing()],
//   tracesSampleRate: import.meta.env.DEV ? undefined : 0.1,
// });

const queryClient = new QueryClient({
  queryCache: new QueryCache({
    onError: (error) => {
      message.warn("An API request failed", 6);
      console.log(error);
    },
  }),
  defaultOptions: {
    queries: {
      refetchOnMount: false,
      refetchOnWindowFocus: false,
      refetchOnReconnect: false,
      retry: 1,
    },
  },
});

i18n.use(initReactI18next).init({
  resources: {
    en: {
      translation: { ...en },
    },
    zt: {
      translation: { ...zt },
    },
  },
  lng: "en",
  fallbackLng: "en",
  interpolation: {
    escapeValue: false,
  },
});

// eslint-disable-next-line @typescript-eslint/no-non-null-assertion
createRoot(document.getElementById("root")!).render(
  <WagmiConfig config={wagmiConfig}>
    <Provider>
      <QueryClientProvider client={queryClient}>
        <AppRouter />
        <ReactQueryDevtools initialIsOpen={false} />
      </QueryClientProvider>
    </Provider>
  </WagmiConfig>
);
