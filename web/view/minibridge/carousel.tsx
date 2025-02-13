import { forwardRef, useImperativeHandle } from "react";
import { Carousel } from "antd";
import noticeIcon from "../../assets/img/notice.svg";
import style from "./index.module.scss";
import { CloseOutlined } from "@ant-design/icons";
import { useAtom } from "jotai";
import { closeCarouselTimeAtom } from "../../atoms/atoms";
import { useNavigate } from "react-router-dom";

const TopCarousel = forwardRef((props, ref) => {
  useImperativeHandle(ref, () => ({}));
  const [closeCarouselTime, setCloseCarouselTime] = useAtom(
    closeCarouselTimeAtom
  );
  const nowTime = +new Date();
  const navigate = useNavigate();
  return (
    <div
      className={style.topCarousel}
      data-show={nowTime > Number(closeCarouselTime) + 86400000 * 2.5}
    >
      <img src={noticeIcon} alt={"notice"} className={style.noticeIcon} />
      <CloseOutlined
        className={style.closeIcon}
        onClick={() => {
          setCloseCarouselTime(+new Date());
        }}
      />
      <Carousel
        effect={"fade"}
        autoplaySpeed={7000}
        autoplay={true}
        dots={false}
        speed={500}
      >
        {/*<span className={style.carouselLine}>*/}
        {/*  🎉*/}
        {/*  <i className={style.spacing} />*/}
        {/*  <a*/}
        {/*    target={"_blank"}*/}
        {/*    href={*/}
        {/*      "https://docs.chaineye.tools/minibridge-api-docs/bridge-batch-requests"*/}
        {/*    }*/}
        {/*  >*/}
        {/*    API batch tranfer is live! <i>Click</i> to see how*/}
        {/*  </a>*/}
        {/*</span>*/}
        <span className={style.carouselLine}>
          🎉
          <i className={style.spacing} />
          <a
            target={"_blank"}
            href={
              "https://scalebit.xyz/reports/20240729-Minibridge-Final-Audit-Report.pdf"
            }
            rel="noopener"
          >
            MiniBridge is successfully audited by Scalebit.
          </a>
        </span>

      </Carousel>
    </div>
  );
});
TopCarousel.displayName = "TopCarousel";
export default TopCarousel;
