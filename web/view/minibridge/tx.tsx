import classNames from "classnames";
import * as Sentry from "@sentry/react";
import * as R from "ramda";
import { Modal, Select, Tooltip, Spin } from "antd";
import "antd/es/select/style";
import "antd/es/modal/style";
import "antd/es/tooltip/style";
import "antd/es/spin/style";
import { InfoCircleOutlined } from "@ant-design/icons";
import {
  useAccount,
  useBalance,
  useFeeData,
  useNetwork,
  useSwitchNetwork,
  useTransaction,
} from "wagmi";
import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useAtom } from "jotai";
import { FetchBalanceResult } from "@wagmi/core/dist/index";
import moment from "moment";
import numeral from "numeral";
import { ethers } from "ethers";
import { getPublicClient } from "@wagmi/core";
import { useWaitForTransaction } from "wagmi";
import { useTranslation } from "react-i18next";
import { miniBridgeAtom } from "../../atoms/atoms";
// import { getIconSrc } from "../../utils/icon";
import {
  useMiniBridgeHistory,
  useMiniBridgeInfo,
} from "../../hooks/useOtherApi";
import {
  MiniBridgeChainType,
  MiniBridgeRouteType,
  ReturnTxType,
} from "../../types";
import style from "./index.module.scss";
import { chainId2IconUrl } from "./index";

const Title = () => {
  const { t } = useTranslation();
  return (
    <>
      <span className={style.homeTitle}>
        <img src={"./biteye.png"} className={style.titleIcon} />
        Mini Bridge
      </span>
      <span className={style.updateTime}>
        {t("headerTips1")}
        <a href={"https://t.me/chaineye"} target={"_blank"} rel="noopener">
          {t("headerTips2")}
        </a>
      </span>
    </>
  );
};
let pageTimer: any;

function MiniBridgeTxPage() {
  const navigate = useNavigate();
  const routeParam = useParams();
  const [miniBridgeInfo, setMiniBridgeInfo] = useAtom(miniBridgeAtom);
  const [myPublicClient, setMyPublicClient] = useState<any>();
  const { address: myAddress } = useAccount();
  const [toTxStatus, setToTxStatus] = useState("");
  const tx = R.path([String(routeParam?.hash)], miniBridgeInfo) as {
    fromChainId: number;
    toChainId: number;
    fromInput: string;
    myAddress: `0x${string}`;
    toAddress: `0x${string}`;
    status: number;
    hash: string;
    txValueBigInt: string;
    preTransferBalance: string;
    time: number;
    formExplorer: string;
    toExplorer: string;
    recAddress: string;
  };

  const { data: balance, refetch: reFetchBalance } = useBalance({
    address: tx?.myAddress,
    chainId: tx?.toChainId,
  });
  const { data: historyJson, refetch: reFetchHistory } = useMiniBridgeHistory(
    tx?.myAddress
  );
  const returnTx = R.find((x: ReturnTxType) => {
    return (
      String(x?.fromtx).toLocaleLowerCase() ===
      String(tx?.hash).toLocaleLowerCase()
    );
  }, historyJson || []) as ReturnTxType;
  const toTxHash = R.pathOr("0x", ["totx"], returnTx) as `0x${string}`;
  useEffect(() => {
    pageTimer = setInterval(async () => {
      if (tx && (tx.status === 1 || tx.status === 3)) {
        reFetchBalance().then((r) => r);
        reFetchHistory().then((r) => r);
        // reFetchTxData().then((r) => r);
      }
    }, 5000);
    return () => {
      pageTimer && clearInterval(pageTimer);
    };
  }, [tx, myPublicClient, reFetchBalance, reFetchHistory]);
  // const { chains } = useNetwork();
  const { data: configData, isFetching: isFetchConfig } = useMiniBridgeInfo();
  const configChain = R.map((x) => {
    return R.mergeRight(x, {
      id: x.chainid,
    });
  }, R.pathOr([], ["chains"], configData) as MiniBridgeChainType[]) as any[];
  useEffect(() => {
    if (balance && returnTx && tx && tx.status === 1 && routeParam?.hash) {
      const status = R.path(["status"], returnTx);
      status && setToTxStatus(String(status));
      const expectedBalance =
        BigInt(tx.preTransferBalance) +
        ethers.utils.parseEther(String(Number(tx.fromInput) || 0)).toBigInt();
      if (balance.value >= expectedBalance && status === "sent") {
        pageTimer && clearInterval(pageTimer);
        setMiniBridgeInfo(
          R.mergeRight(miniBridgeInfo, {
            [String(routeParam?.hash)]: R.mergeRight(tx, { status: 2 }),
          })
        );
      } else if (status === "finished") {
        pageTimer && clearInterval(pageTimer);
        setMiniBridgeInfo(
          R.mergeRight(miniBridgeInfo, {
            [String(routeParam?.hash)]: R.mergeRight(tx, { status: 2 }),
          })
        );
      }
    }
  }, [
    miniBridgeInfo,
    routeParam?.hash,
    setMiniBridgeInfo,
    returnTx,
    tx,
    balance,
  ]);
  if (!myPublicClient && tx && tx.toChainId) {
    setMyPublicClient(
      getPublicClient({
        chainId: tx.toChainId,
      })
    );
  }
  const fromIcon = chainId2IconUrl(tx.fromChainId);
  const toIcon = chainId2IconUrl(tx.toChainId);
  const { t } = useTranslation();
  const statusI18n = {
    sent: t("tx.sending"),
    pending: t("tx.processing"),
    finished: t("tx.success"),
  };
  return (
    <div className={classNames(style.mainContainer, "beautiful-scrollbar-cex")}>
      <Title />
      {tx && !isFetchConfig ? (
        <div className={style.miniBridgeBody}>
          <div className={style.processing}>
            {tx.status === 2
              ? t("tx.success")
              : R.pathOr(toTxStatus, [toTxStatus], statusI18n) ||
                t("tx.processing")}
            <Spin spinning={tx.status !== 2} style={{ marginLeft: 15 }} />
          </div>
          <div className={style.lineTxInfoWrap}>
            <span>{t("tx.time")}</span>
            <span>{moment(tx.time).format("YYYY/MM/DD HH:mm:ss")}</span>
          </div>
          <div className={style.lineTxInfoWrap}>
            <span>{t("tx.amount")}</span>
            <span>${numeral(tx.fromInput).format("0,0.000000")} ETH</span>
          </div>
          {tx.recAddress ? (
            <div className={style.lineTxInfoWrap}>
              <span>{t("home.transferTo")}</span>
              <span style={{ fontSize: 13 }}>{tx.recAddress}</span>
            </div>
          ) : null}
          <div className={style.fromToBoxWrap}>
            <div className={style.fromXBox}>
              <span>{t("from")}</span>
              <span>
                <img
                  src={fromIcon}
                  className={"mini-bridge-token-icon"}
                  alt={"-"}
                />
                {R.find((x) => x.id === tx.fromChainId, configChain)?.name}
              </span>
              <span>
                Tx:{" "}
                <a
                  className={style.txLink}
                  target={"_blank"}
                  href={
                    tx.formExplorer ? `${tx.formExplorer}tx/${tx.hash}` : ""
                  }
                  rel="noopener"
                >
                  {tx.hash}
                </a>
              </span>
            </div>
            <div className={style.toXBox}>
              <span>{t("to")}</span>
              <span>
                <img src={toIcon} className={"mini-bridge-token-icon"} />
                {R.find((x) => x.id === tx.toChainId, configChain)?.name}
              </span>
              <span>
                Tx:
                <a
                  className={style.txLink}
                  target={"_blank"}
                  href={
                    tx.toExplorer && toTxHash && toTxHash.length > 10
                      ? `${tx.toExplorer}tx/${toTxHash}`
                      : ""
                  }
                  rel="noopener"
                >
                  {toTxHash && toTxHash.length > 10 ? toTxHash : "pending..."}
                </a>
              </span>
            </div>
          </div>
          <div className={style.lineTips}>⚠️ {t("tx.tips1")}</div>
          <div
            className={style.sendBtn}
            onClick={() => {
              if (tx && tx.status === 1) {
                setMiniBridgeInfo(
                  R.mergeRight(miniBridgeInfo, {
                    [String(myAddress)]: R.mergeRight(tx, { status: 3 }),
                  })
                );
              }
              setTimeout(() => {
                navigate(`/`);
              }, 0);
            }}
          >
            {t("back")}
          </div>
        </div>
      ) : null}
    </div>
  );
}

export default Sentry.withErrorBoundary(MiniBridgeTxPage, {
  fallback: (
    <p className="w-full h-full text-xl">
      Sorry, an unrecoverable error has occurred. Please reload the page and try
      again.
    </p>
  ),
  showDialog: true,
});
