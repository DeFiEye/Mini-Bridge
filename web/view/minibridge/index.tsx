import classNames from "classnames";
import * as Sentry from "@sentry/react";
import * as R from "ramda";
import { Modal, Select, Tooltip, Spin, Tree, message } from "antd";
import { DownOutlined } from "@ant-design/icons";
import "antd/es/select/style";
import "antd/es/modal/style";
import "antd/es/tooltip/style";
import "antd/es/spin/style";
import "antd/es/tree/style";
import "antd/es/message/style";
import { InfoCircleOutlined } from "@ant-design/icons";
import { MetaMaskConnector } from "wagmi/connectors/metaMask";
import {
  mainnet,
  optimism,
  zkSync,
  base,
  linea,
  arbitrum,
} from "@wagmi/core/chains";
import {
  useConnect,
  useAccount,
  useBalance,
  useFeeData,
  useNetwork,
  useSwitchNetwork,
  useSendTransaction,
  usePrepareSendTransaction,
} from "wagmi";
import { useEffect, useRef, useState } from "react";
import numeral from "numeral";
import { useNavigate } from "react-router-dom";
import { useAtom } from "jotai";
import { ethers } from "ethers";
import { useTranslation } from "react-i18next";
import Decimal from "decimal.js";
import { PGN, manta, chainIdToName } from "../../wagmi/chain";
import skrIcon from "../../assets/img/skr.svg";
import swapSvg from "../../assets/img/swap.svg";
import { miniBridgeAtom } from "../../atoms/atoms";
import { useDiscountInfo, useMiniBridgeInfo } from "../../hooks/useOtherApi";
import { MiniBridgeChainType, MiniBridgeRouteType } from "../../types";
import ethIcon from "../../assets/img/asset/eth.svg";
import Capsule from "../../component/capsule";
import style from "./index.module.scss";

export function chainId2IconUrl(chainId: number | string | unknown) {
  return `./chain/${String(
    R.path([Number(chainId)], chainIdToName)
  ).toLocaleLowerCase()}.png`;
}

const { Option } = Select;
const ROUTER_MIN_BALANCE = 0.05;
const BRIDGE_ADDR = "0x00000000000007736e2F9aA5630B8c812E1F3fc9";
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

function MiniBridgePage() {
  const { t } = useTranslation();
  const capsule = useRef();
  const faqTreeData = useFAQData();
  const [expandedKeys, setExpandedKeys] = useState(["0-0"]);
  const { data: configData, isFetching: isFetchConfig } = useMiniBridgeInfo();
  const navigate = useNavigate();
  const minReservation = 0.001;
  const [recAddress, setRecAddress] = useState("");
  const [isShowRec, setIsShowRec] = useState(false);
  const [fromChainId, setFromChainId] = useState(324);
  const [toChainId, setToChainId] = useState(59144);
  const [fromInput, setFromInput] = useState("");
  const { address: myAddress, isConnected } = useAccount();
  const { data: userDiscountInfo, isFetching: isFetchUserDiscount } =
    useDiscountInfo(myAddress);
  const { data: fromBalance, isFetching: isFFromBalance } = useBalance({
    address: myAddress,
    chainId: fromChainId,
    // watch: true,
  });
  const { data: feeData } = useFeeData({
    chainId: fromChainId,
    formatUnits: "ether",
  });
  const { data: toBalance, isFetching: isFToBalance } = useBalance({
    address: myAddress,
    chainId: toChainId,
    // watch: true,
  });

  const { chain: nowChain } = useNetwork();

  const { switchNetwork, isSuccess: isSwitchNetSuccess } = useSwitchNetwork({
    chainId: fromChainId,
  });
  const [modalOpenInfo, setModalOpenInfo] = useState<boolean>();
  const [miniBridgeInfo, setMiniBridgeInfo] = useAtom(miniBridgeAtom);
  const configV = R.path(["version"], configData);
  const configChain = R.map((x) => {
    return R.mergeRight(x, {
      id: x.chainid,
    });
  }, R.pathOr([], ["chains"], configData) as MiniBridgeChainType[]) as any[];

  const configRoutes = R.pathOr(
    [],
    ["routes"],
    configData
  ) as MiniBridgeRouteType[];
  const exceedingBalance = Number(fromInput) > Number(fromBalance?.formatted);
  const nowRoute = R.find((item) => {
    return (
      Number(item.from_chainid) === Number(fromChainId) &&
      item.to_chainid === Number(toChainId)
    );
  }, configRoutes) as MiniBridgeRouteType;
  const minRemain =
    minReservation +
    Number(R.pathOr(0, ["formatted", "maxFeePerGas"], feeData));
  const maxAvailableBalance = Number(fromBalance?.formatted) - minRemain;
  const amountMax = Number(R.pathOr(0.1, ["amount_max"], nowRoute));
  const amountMin = Number(R.pathOr(0.0001, ["amount_min"], nowRoute));
  const originalFixedFee = Number(R.pathOr(0.0001, ["fee_fixed"], nowRoute));
  let fixedFee = originalFixedFee;
  const discountNum = Number(R.pathOr(1, ["discount"], userDiscountInfo));
  if (discountNum < 1) {
    const fixedFeeDecimal = new Decimal(originalFixedFee);
    fixedFee = fixedFeeDecimal.times(discountNum).toNumber();
  }
  const confirmCode = 8000 + Number(R.pathOr(0, ["to_id"], nowRoute));
  const bridgeAddr = BRIDGE_ADDR; //R.path(["bridge"], nowRoute) as `0x${string}`
  const { data: bridgeBalance } = useBalance({
    address: bridgeAddr,
    chainId: toChainId,
  });

  function sendBtnText() {
    if (isFetchConfig) {
      return t("loading");
    }
    if (!isConnected) {
      return t("home.btn-caw");
    }
    if (!fromBalance?.value || Number(fromInput) > maxAvailableBalance) {
      return t("home.btn-if");
    }
    if (exceedingBalance || maxAvailableBalance <= amountMin) {
      return t("home.btn-if");
    }
    if (!configV && !isFetchConfig) {
      return t("home.btn-ft");
    }
    if (Number(bridgeBalance?.formatted) < ROUTER_MIN_BALANCE) {
      return t("home.btn-il");
    }
    if (!nowRoute) {
      return t("home.btn-st");
    }
    return t("home.btn-send");
  }

  function formatBalance(balance: string | undefined) {
    if (!balance) {
      return "0.000000";
    }
    return numeral(balance).format("0,0.000000");
  }

  const txValueBigInt =
    ethers.utils.parseEther(String(Number(fromInput) || 0)).toBigInt() +
    ethers.utils.parseEther(String(fixedFee)).toBigInt() +
    BigInt(confirmCode);
  const prepareSendObject = {
    to: String(bridgeAddr),
    value: txValueBigInt,
    chainId: fromChainId,
    account: myAddress,
  };
  if (
    recAddress &&
    String(recAddress).length >= 40 &&
    recAddress !== myAddress
  ) {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    prepareSendObject["data"] = recAddress;
  }
  const { config: txConfig } = usePrepareSendTransaction(prepareSendObject);
  const {
    data: sendTxData,
    isSuccess: isSendTxSuccess,
    sendTransaction,
  } = useSendTransaction(txConfig);

  useEffect(() => {
    setFromInput("");
  }, [fromChainId, toChainId]);
  useEffect(() => {
    if (sendTxData && isSendTxSuccess) {
      setMiniBridgeInfo(
        R.mergeRight(miniBridgeInfo, {
          [String(myAddress)]: {
            fromChainId,
            toChainId,
            fromInput,
            myAddress,
            toAddress: bridgeAddr,
            status: 1,
            recAddress,
            hash: sendTxData.hash,
            txValueBigInt: txValueBigInt.toString(),
            preTransferBalance: toBalance?.value.toString(),
            time: +new Date(),
            formExplorer: R.pathOr(
              "",
              ["explorer"],
              R.find((x) => x.id === fromChainId, configChain)
            ),
            toExplorer: R.pathOr(
              "",
              ["explorer"],
              R.find((x) => x.id === toChainId, configChain)
            ),
          },
        })
      );
      setFromInput("");
    }
  }, [isSendTxSuccess]);
  useEffect(() => {
    if (isSwitchNetSuccess && nowChain?.id === fromChainId) {
      setModalOpenInfo(true);
    }
  }, [isSwitchNetSuccess]);
  useEffect(() => {
    const nowTxStatus = Number(
      R.pathOr(-1, [String(myAddress), "status"], miniBridgeInfo)
    );
    if (nowTxStatus === 1) {
      navigate(`/${myAddress}`);
    }
  }, [miniBridgeInfo, myAddress, navigate]);
  // console.log(nowRoute);
  return (
    <div className={classNames(style.mainContainer, "beautiful-scrollbar-cex")}>
      <Capsule ref={capsule} />
      <Title />
      <Spin spinning={isFetchConfig || isFetchUserDiscount}>
        <div className={style.miniBridgeBody}>
          <div className={style.topInterval} />
          <div className={style.tokenWrap}>
            <div>
              {t("home.token")}
              <Select
                bordered={false}
                placement={"bottomRight"}
                className={"select-mini-bridge select-mini-bridge-disabled"}
                popupClassName={"select-popup-mini-bridge"}
                value={"ETH"}
                showArrow={false}
                style={{ width: 80, marginLeft: 5, border: "none" }}
              >
                <Option key={"ETH"} value={"ETH"}>
                  <img
                    className={"mini-bridge-token-icon"}
                    src={ethIcon}
                    alt={"-"}
                  />
                  {"ETH"}
                </Option>
              </Select>
            </div>
            <div
              className={style.historyLink}
              data-connect={isConnected}
              onClick={() => {
                navigate(`/history`);
              }}
            >
              {t("home.history")}
            </div>
          </div>
          <div className={style.fromBox}>
            <div className={style.boxTitle}>
              <span>{t("from")}</span>
              <span className={style.walletBalance}>
                {isFFromBalance
                  ? t("loading")
                  : `${t("home.walletBalance")}: ${formatBalance(
                      fromBalance?.formatted
                    )}`}
              </span>
            </div>
            <div className={style.box}>
              <Select
                bordered={false}
                placement={"bottomRight"}
                className={"select-mini-bridge"}
                popupClassName={"select-popup-mini-bridge"}
                value={fromChainId}
                style={{ width: 160 }}
                onSelect={async (value: any) => {
                  if (value === toChainId) {
                    setToChainId(fromChainId);
                  }
                  setFromChainId(value);
                }}
              >
                {R.map((chain) => {
                  const icon = chainId2IconUrl(chain.id);
                  return (
                    <Option key={chain.id} value={chain.id}>
                      <img
                        className={"mini-bridge-token-icon"}
                        src={icon}
                        alt={"-"}
                      />
                      {chain.name}
                    </Option>
                  );
                }, configChain)}
              </Select>
              <div className={style.inputWrap}>
                <input
                  placeholder={`${amountMin} ~ ${amountMax}`}
                  value={fromInput}
                  onInput={(e) => {
                    try {
                      let v = R.pathOr("", ["target", "value"], e);
                      if (String(v).length > 8) {
                        return false;
                      }
                      v = v.replace(/[^\d.]/g, "");
                      setFromInput(v);
                    } catch (err) {
                      setFromInput("");
                      // console.log(err)
                    }
                  }}
                />
                <span
                  className={style.max}
                  onClick={() => {
                    if (!isConnected || maxAvailableBalance <= 0) {
                      return;
                    }
                    setFromInput(
                      numeral(Math.min(maxAvailableBalance, amountMax)).format(
                        "0,0.000000"
                      )
                    );
                  }}
                >
                  {t("home.max")}
                </span>
              </div>
            </div>
          </div>
          <div
            className={style.swapWrap}
            onClick={() => {
              const f = fromChainId;
              setFromChainId(toChainId);
              setToChainId(f);
              setFromInput("");
            }}
          >
            <img src={swapSvg} alt={"-"} />
          </div>
          <div className={style.toBox}>
            <div className={style.boxTitle}>
              <span>{t("to")}</span>
              <span className={style.walletBalance}>
                {isFToBalance
                  ? t("loading")
                  : `${t("home.walletBalance")}: ${formatBalance(
                      toBalance?.formatted
                    )}`}
              </span>
            </div>
            <div className={style.box}>
              <Select
                bordered={false}
                placement={"bottomRight"}
                className={"select-mini-bridge"}
                popupClassName={"select-popup-mini-bridge"}
                value={toChainId}
                style={{ width: 160 }}
                onSelect={(value: any) => {
                  if (value === fromChainId) {
                    setFromChainId(toChainId);
                  }
                  setToChainId(value);
                }}
              >
                {R.map((chain) => {
                  const icon = chainId2IconUrl(chain.id);
                  return (
                    <Option key={chain.id} value={chain.id}>
                      <img
                        className={"mini-bridge-token-icon"}
                        src={icon}
                        alt={"-"}
                      />
                      {chain.name}
                    </Option>
                  );
                }, configChain)}
              </Select>
              <div className={style.inputWrap}>
                <input
                  style={{ pointerEvents: "none" }}
                  value={
                    // - fixedFee
                    Number(fromInput) >= amountMin
                      ? numeral(Number(fromInput)).format("0,0.00000")
                      : 0
                  }
                  disabled={true}
                />
                <span className={style.max} style={{ width: 25 }}>
                  <Tooltip
                    placement="top"
                    overlayClassName={"px-5"}
                    title={<p>{t("home.sendFee")}</p>}
                  >
                    <InfoCircleOutlined style={{ fontSize: 15 }} />
                  </Tooltip>
                </span>
              </div>
            </div>
          </div>
          <div className={style.lineTxInfoWrap}>
            <span>
              {t("home.bridgeFee")}
              <Tooltip
                placement="top"
                overlayClassName={"px-5"}
                title={<p>{t("home.sendFee")}</p>}
              >
                <InfoCircleOutlined
                  style={{ fontSize: 15, color: "#00ffd1", marginLeft: 5 }}
                />
              </Tooltip>
            </span>
            <span style={{ color: "#00ffd1" }}>0 ETH</span>
          </div>
          <div className={style.lineTxInfoWrap}>
            <span>{t("home.destTxCost")}</span>
            {originalFixedFee === fixedFee ? (
              <span> {fixedFee} ETH </span>
            ) : (
              <span>
                <i className={style.originalFixedFee}>{originalFixedFee}</i>
                <i className={style.nowFixedFee}>{fixedFee}</i>
                ETH
                <Tooltip
                  placement="top"
                  overlayClassName={"px-5"}
                  title={<p>{R.pathOr("", ["reason"], userDiscountInfo)}</p>}
                >
                  <InfoCircleOutlined
                    style={{ fontSize: 15, color: "#00ffd1", marginLeft: 5 }}
                  />
                </Tooltip>
              </span>
            )}
          </div>
          <div className={style.lineTxInfoWrap}>
            <span>{t("home.totalCost")}</span>
            <span>{fixedFee} ETH</span>
          </div>
          <div className={style.tipsTop} />
          {Number(fromInput) > amountMax ? (
            <div className={style.lineTips}>
              {`⚠️${t("home.maxLimitTips")} (${amountMax}). ${t(
                "home.limitTryAgainMax"
              )}`}
            </div>
          ) : null}
          {Number(fromInput) > 0 && Number(fromInput) < amountMin ? (
            <div className={style.lineTips}>
              {`⚠️${t("home.minLimitTips")} (${amountMin}). ${t(
                "home.limitTryAgainMin"
              )}`}
            </div>
          ) : null}
          {fromInput &&
          Number(bridgeBalance?.formatted) < ROUTER_MIN_BALANCE ? (
            <div className={style.lineTips}>
              {`⚠️${t("home.tryAgainTips")}`}
            </div>
          ) : null}
          {!configV && !isFetchConfig ? (
            <div className={style.lineTips}>⚠️{t("home.failedLoadConfig")}</div>
          ) : null}
          <div className={style.sendBtnWrap}>
            <div
              className={style.sendBtn}
              data-disabled={
                !isConnected
                  ? false
                  : !fromBalance?.value ||
                    !fromInput ||
                    Number(fromInput) > amountMax ||
                    Number(fromInput) < amountMin ||
                    maxAvailableBalance <= amountMin ||
                    exceedingBalance ||
                    !configV ||
                    !nowRoute ||
                    Number(bridgeBalance?.formatted) < ROUTER_MIN_BALANCE ||
                    Number(fromInput) > maxAvailableBalance
              }
              onClick={() => {
                if (!isConnected) {
                  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                  // @ts-ignore
                  capsule.current && capsule.current?.showConnectUi();
                  return;
                }
                try {
                  if (
                    isShowRec &&
                    recAddress &&
                    !ethers.utils.isAddress(recAddress)
                  ) {
                    message.warn(t("home.invalidAddress")).then((r) => r);
                    return;
                  }
                } catch (err) {
                  message.warn(t("home.invalidAddress")).then((r) => r);
                  return;
                }
                if (nowChain?.id === fromChainId) {
                  setModalOpenInfo(true);
                } else {
                  if (switchNetwork) {
                    switchNetwork();
                  }
                }
              }}
            >
              {sendBtnText()}
            </div>
            <div
              className={style.choseWalletWrap}
              onClick={() => {
                setIsShowRec(!isShowRec);
                setRecAddress("");
              }}
            >
              <img src={skrIcon} alt={"-"} />
            </div>
          </div>
          <div className={style.recAddress} data-rec={isShowRec}>
            <input
              value={recAddress}
              disabled={modalOpenInfo}
              placeholder={t("home.sendAddrInputTips")}
              onInput={(e) => {
                const v = R.pathOr("", ["target", "value"], e);
                setRecAddress(v);
              }}
            />
          </div>
          <div className={style.fqaWrap}>
            <h2>{t("faq.title")}</h2>
            <Tree
              expandedKeys={expandedKeys}
              rootClassName={"mini-bridge-fqa-tree"}
              switcherIcon={<DownOutlined />}
              onExpand={(eKeys, e) => {
                const itemKey = R.pathOr("", ["node", "key"], e);
                if (expandedKeys.includes(itemKey)) {
                  setExpandedKeys(R.without([itemKey], expandedKeys));
                } else {
                  setExpandedKeys(R.append(itemKey, expandedKeys));
                }
              }}
              onSelect={(selectedKeys, e) => {
                const itemKey = R.pathOr("", ["node", "key"], e);
                if (expandedKeys.includes(itemKey)) {
                  setExpandedKeys(R.without([itemKey], expandedKeys));
                } else {
                  setExpandedKeys(R.append(itemKey, expandedKeys));
                }
              }}
              treeData={faqTreeData}
            />
          </div>
        </div>
      </Spin>
      <Modal
        className={"mini-bridge-modal"}
        width={Math.min(Math.max(290, document.body.clientWidth * 0.8), 420)}
        onCancel={() => setModalOpenInfo(false)}
        open={Boolean(modalOpenInfo)}
        footer={null}
        maskStyle={{ background: "rgba(0, 0, 0, 0.75)" }}
        bodyStyle={{
          background: "rgba(15,21,43,0.85)",
          border: "1px solid rgba(255,255,255,0.05)",
          boxShadow: "0px 0px 30px 0px #00FFD133",
          borderRadius: 10,
          backdropFilter: "blur(4px)",
        }}
      >
        <div className={style.lineTop} />
        <div className={style.lineTxInfoWrap}>
          <span>
            {t("home.sendFee")}
            <Tooltip
              placement="top"
              overlayClassName={"px-5"}
              title={<p>{t("home.sendFee")}</p>}
            >
              <InfoCircleOutlined
                style={{ fontSize: 15, color: "#00ffd1", marginLeft: 5 }}
              />
            </Tooltip>
          </span>
          <span style={{ color: "#00ffd1" }}>0 ETH</span>
        </div>
        <div className={style.lineTxInfoWrap}>
          <span>{t("home.destTxCost")}</span>
          {originalFixedFee === fixedFee ? (
            <span> {fixedFee} ETH </span>
          ) : (
            <span>
              <i className={style.originalFixedFee}>{originalFixedFee}</i>
              <i className={style.nowFixedFee}>{fixedFee}</i>
              ETH
            </span>
          )}
        </div>
        <div className={style.lineTxInfoWrap}>
          <span>{t("home.totalCost")}</span>
          <span>{fixedFee} ETH</span>
        </div>
        <div className={style.line} />
        <div className={style.lineTxInfoWrap}>
          <span>
            {t("home.confirmCode")}
            <Tooltip
              placement="top"
              overlayClassName={"px-5"}
              title={<p>{t("home.confirmCodeTips")}</p>}
            >
              <InfoCircleOutlined
                style={{ fontSize: 15, color: "#00ffd1", marginLeft: 5 }}
              />
            </Tooltip>
          </span>
          <span style={{ color: "#00ffd1" }}>{confirmCode}</span>
        </div>
        <div className={style.lineTxInfoWrap}>
          <span>{t("home.totalCost")}</span>
          {/*{txValueBigInt.toString()}*/}
          <span>
            {`${numeral(Number(fromInput) + Number(fixedFee)).format(
              "0,0.00000"
            )}...0${confirmCode}`}{" "}
            ETH
          </span>
        </div>
        <div className={style.lineTxInfoWrap}>
          <span>{t("home.received")}</span>
          <span>{numeral(Number(fromInput)).format("0,0.00000")} ETH</span>
        </div>
        {recAddress ? (
          <div className={style.lineTxInfoWrap}>
            <span>{t("home.transferTo")}</span>
            <span style={{ fontSize: 12 }}>{recAddress}</span>
          </div>
        ) : null}
        <div className={style.linePrompt}>
          <InfoCircleOutlined
            style={{ fontSize: 15, color: "#00ffd1", marginRight: 10 }}
          />
          {t("home.ycTips")}
        </div>
        <div
          className={style.sendBtn}
          onClick={async () => {
            setModalOpenInfo(false);
            if (sendTransaction) {
              await sendTransaction();
            }
          }}
        >
          {t("home.confirm")}
        </div>
      </Modal>
    </div>
  );
}

const useFAQData = () => {
  const { t } = useTranslation();
  return [
    {
      title: t("faq.00"),
      key: "0-0",
      children: [
        {
          title: t("faq.000"),
          key: "0-0-0",
        },
      ],
    },
    {
      title: t("faq.01"),
      key: "0-1",
      children: [
        {
          title: t("faq.010"),
          key: "0-1-0",
        },
      ],
    },
    {
      title: t("faq.02"),
      key: "0-2",
      children: [
        {
          title: t("faq.020"),
          key: "0-2-0",
        },
      ],
    },
    {
      title: t("faq.03"),
      key: "0-3",
      children: [
        {
          title: t("faq.030"),
          key: "0-3-0",
        },
      ],
    },
    {
      title: t("faq.04"),
      key: "0-4",
      children: [
        {
          title: t("faq.040"),
          key: "0-4-0",
        },
      ],
    },
  ];
};
export default Sentry.withErrorBoundary(MiniBridgePage, {
  fallback: (
    <p className="w-full h-full text-xl">
      Sorry, an unrecoverable error has occurred. Please reload the page and try
      again.
    </p>
  ),
  showDialog: true,
});
