import classNames from "classnames";
import * as Sentry from "@sentry/react";
import * as R from "ramda";
import "antd/es/select/style";
import "antd/es/modal/style";
import "antd/es/tooltip/style";
import "antd/es/spin/style";
import AutoSizer from "react-virtualized-auto-sizer";
import { FixedSizeList as List } from "react-window";
import { useAccount } from "wagmi";
import { CSSProperties, useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import moment from "moment";
import { LeftOutlined } from "@ant-design/icons";
import { useTranslation } from "react-i18next";
import {
  useMiniBridgeHistory,
  useMiniBridgeInfo,
} from "../../hooks/useOtherApi";
import style from "./index.module.scss";
import { chainId2IconUrl } from "./index";

const Title = () => {
  const navigate = useNavigate();
  const { t } = useTranslation();
  return (
    <div className={style.headerTitle}>
      <span className={style.homeTitle}>
        <LeftOutlined
          className={style.backIcon}
          onClick={() => {
            navigate("/");
          }}
        />
        <img src={"./biteye.png"} className={style.titleIcon} />
        Mini Bridge
      </span>
      <span className={style.updateTime}>
        {t("headerTips1")}
        <a href={"https://t.me/chaineye"} target={"_blank"} rel="noopener">
          {t("headerTips2")}
        </a>
      </span>
    </div>
  );
};

function MiniBridgeHistoryPage() {
  const { t } = useTranslation();
  const statusToI18n = {
    pending: t("history.pending"),
    sent: t("history.sent"),
    finished: t("history.finished"),
  };
  const { data: configData, isFetching: isFetchConfig } = useMiniBridgeInfo();
  const { address: myAddress, isConnected } = useAccount();
  const {
    data: historyJson,
    refetch: reFetchHistory,
    isFetching: isFHistory,
  } = useMiniBridgeHistory(myAddress || "0x");
  const sortFn = function (a: any, b: any) {
    const timeA = R.pathOr(0, ["fromtime"], a);
    const timeB = R.pathOr(0, ["fromtime"], b);
    return timeB - timeA;
  };
  const formatHistoryJson = R.sort(sortFn, historyJson || []);
  const configChains = R.pathOr([], ["chains"], configData);
  const ListRow = (info: { index: number; style: CSSProperties }) => {
    const item = R.pathOr(
      { fromChain: -1, toChain: -1 },
      [info.index],
      formatHistoryJson
    );
    const formChain = R.find(
      (x) =>
        Number(R.path(["internalId"], x)) ===
        Number(R.path(["fromchain"], item)),
      configChains
    );
    const toChain = R.find(
      (x) =>
        Number(R.path(["internalId"], x)) === Number(R.path(["tochain"], item)),
      configChains
    );
    const formChainId = R.path(["chainid"], formChain);
    const toChainId = R.path(["chainid"], toChain);
    const formChainName = R.path(["name"], formChain);
    const toChainName = R.path(["name"], toChain);
    const formTx = R.path(["fromtx"], item);
    const toTx = R.path(["totx"], item);
    const fromTime = moment(R.pathOr(0, ["fromtime"], item) * 1000).format(
      "YYYY-MM-DD HH:mm"
    );
    const formExplorer = R.pathOr("", ["explorer"], formChain);
    const toExplorer = R.pathOr("", ["explorer"], toChain);
    const status = R.pathOr("unknown", ["status"], item);
    const fromIcon = chainId2IconUrl(formChainId);
    const toIcon = chainId2IconUrl(toChainId);
    return (
      <div
        style={info.style}
        className={classNames(style.historyLine)}
        data-index={info.index}
      >
        <div className={style.historyLineInnerWrap}>
          <div className={style.fromXBox}>
            <span>{t("from")}</span>
            <span>
              <img
                src={fromIcon}
                className={"mini-bridge-token-icon"}
                alt={"-"}
              />
              <>{String(formChainName)}</>
            </span>
            <span>
              Tx:{" "}
              <a
                className={style.txLink}
                target={"_blank"}
                href={`${formExplorer}tx/${formTx}`}
                rel="noopener"
              >
                {String(formTx)}
              </a>
            </span>
          </div>
          <div className={style.toXBox}>
            <span>{t("to")}</span>
            <span>
              <img src={toIcon} className={"mini-bridge-token-icon"} />
              <>{String(toChainName)}</>
            </span>
            <span>
              Tx:
              <a
                className={style.txLink}
                target={"_blank"}
                href={`${toExplorer}tx/${toTx}`}
                rel="noopener"
              >
                {String(toTx)}
              </a>
            </span>
          </div>
          <div className={style.status}>
            <span className={style.time}>
              {R.pathOr(status, [status], statusToI18n)} ({fromTime})
            </span>
            {/*<span className={style.statusText} data-status={status}>*/}
            {/*  /!*<CheckCircleOutlined className={style.statusIcon} />*!/*/}
            {/*  {status}*/}
            {/*</span>*/}
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className={classNames(style.mainContainer, "scrollbar-none")}>
      <Title />
      {/* eslint-disable-next-line react/jsx-no-undef */}
      <div style={{ height: 20 }} />
      {!historyJson || !configData ? (
        <span className={style.historyTips}>
          {isFetchConfig || isFHistory
            ? "Loading..."
            : !isConnected
            ? "Please connect a wallet first"
            : "No data."}
        </span>
      ) : (
        <div className={style.historyAutoSizerWrap}>
          <AutoSizer style={{ minWidth: "100%", height: "100%" }}>
            {(size: { width: number; height: number }) => (
              <List
                style={{ minWidth: "100%" }}
                className={"scrollbar-hidden"}
                height={size.height}
                width={size.width}
                itemCount={R.pathOr(0, ["length"], formatHistoryJson)}
                itemSize={160}
              >
                {ListRow}
              </List>
            )}
          </AutoSizer>
        </div>
      )}
    </div>
  );
}

export default Sentry.withErrorBoundary(MiniBridgeHistoryPage, {
  fallback: (
    <p className="w-full h-full text-xl">
      Sorry, an unrecoverable error has occurred. Please reload the page and try
      again.
    </p>
  ),
  showDialog: true,
});
