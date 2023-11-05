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

import style from "./index.module.scss";

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

function MiniBridgeRewardPage() {
  return (
    <div className={classNames(style.mainContainer, "beautiful-scrollbar-cex")}>
      <Title />
      <div className={style.miniBridgeBody}>
        <div className={style.rewardDesBox}>
          <div className={style.left}>
            <h2>Mini bridge reward program</h2>
            <span className={style.desSpan}>
              Join the referral program and earn a portion of fees in $MBP for
              transfers made from your unique referral link.
            </span>
          </div>
          <div className={style.right}>
            <a className={style.learnMore}>Learn more</a>
            <a className={style.getLink}>Get Your Link</a>
          </div>
        </div>
        <div className={style.rewardMiniTitle}>My Rewards</div>
        <div className={style.myRewardsBox}>
          <div className={style.left}></div>
          <div className={style.right}></div>
        </div>
        <div className={style.rewardMiniTitle}>My Referrals</div>
        <div className={style.rewardMiniTitle}>Gas reward details</div>
        <div className={style.rewardMiniTitle}>$pMNB details</div>
      </div>
    </div>
  );
}

export default Sentry.withErrorBoundary(MiniBridgeRewardPage, {
  fallback: (
    <p className="w-full h-full text-xl">
      Sorry, an unrecoverable error has occurred. Please reload the page and try
      again.
    </p>
  ),
  showDialog: true,
});
