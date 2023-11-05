import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import MiniBridgePage from "./view/minibridge/index";
import MiniBridgeTxPage from "./view/minibridge/tx";
import MiniBridgeHistoryPage from "./view/minibridge/history";
import MiniBridgeRewardPage from "./view/minibridge/reward";
export default function AppRouter() {
  const skin = "dark";
  // const skin = "light";

  return (
    <BrowserRouter basename={import.meta.env.BASE_URL}>
      <div id={"skin"} data-theme={skin}>
        <Routes>
          <Route path="/" element={<MiniBridgePage />} />
          <Route path="/:hash" element={<MiniBridgeTxPage />} />
          <Route path="/history" element={<MiniBridgeHistoryPage />} />
          <Route path="/reward" element={<MiniBridgeRewardPage />} />
        </Routes>
      </div>
    </BrowserRouter>
  );
}
