pragma solidity 0.4.24;

contract RouletteMatrix
{

    address developer;
    uint16 constant maxTypeBets = 157;
    mapping(uint16 => uint8) private winMatrix;

    constructor() public {
        developer = msg.sender;
    }

    //    enum BetTypes{number0, number1, number2, number3, number4, number5, number6, number7, number8, number9,
    //        number10, number11, number12, number13, number14, number15, number16, number17, number18, number19, number20, number21,
    //        number22, number23, number24, number25, number26, number27, number28, number29, number30, number31, number32, number33,
    //        number34, number35, number36, red, black, odd, even, dozen1, dozen2, dozen3, column1, column2, column3, low, high,
    //        pair_01, pair_02, pair_03, pair_12, pair_23, pair_36, pair_25, pair_14, pair_45, pair_56, pair_69, pair_58, pair_47,
    //        pair_78, pair_89, pair_912, pair_811, pair_710, pair_1011, pair_1112, pair_1215, pair_1518, pair_1617, pair_1718, pair_1720,
    //        pair_1619, pair_1922, pair_2023, pair_2124, pair_2223, pair_2324, pair_2528, pair_2629, pair_2730, pair_2829, pair_2930, pair_1114,
    //        pair_1013, pair_1314, pair_1415, pair_1316, pair_1417, pair_1821, pair_1920, pair_2021, pair_2225, pair_2326, pair_2427, pair_2526,
    //        pair_2627, pair_2831, pair_2932, pair_3033, pair_3132, pair_3233, pair_3134, pair_3235, pair_3336, pair_3435, pair_3536, corner_0_1_2_3,
    //        corner_1_2_5_4, corner_2_3_6_5, corner_4_5_8_7, corner_5_6_9_8, corner_7_8_11_10, corner_8_9_12_11, corner_10_11_14_13, corner_11_12_15_14,
    //        corner_13_14_17_16, corner_14_15_18_17, corner_16_17_20_19, corner_17_18_21_20, corner_19_20_23_22, corner_20_21_24_23, corner_22_23_26_25,
    //        corner_23_24_27_26, corner_25_26_29_28, corner_26_27_30_29, corner_28_29_32_31, corner_29_30_33_32, corner_31_32_35_34, corner_32_33_36_35,
    //        three_0_2_3, three_0_1_2, three_1_2_3, three_4_5_6, three_7_8_9, three_10_11_12, three_13_14_15, three_16_17_18, three_19_20_21, three_22_23_24,
    //        three_25_26_27, three_28_29_30, three_31_32_33, three_34_35_36, six_1_2_3_4_5_6, six_4_5_6_7_8_9, six_7_8_9_10_11_12, six_10_11_12_13_14_15,
    //        six_13_14_15_16_17_18, six_16_17_18_19_20_21, six_19_20_21_22_23_24, six_22_23_24_25_26_27, six_25_26_27_28_29_30, six_28_29_30_31_32_33,
    //        six_31_32_33_34_35_36}
    // split to pass gas issue
    bool winFactor1Initialzied = false;
    function initWinMatrixFactors1() private {
        require(!winFactor1Initialzied);

        uint16[108] memory matrixIndexes = [10242,12290,12291,10244,12292,12293,10246,12294,12295,10248,12296,12297,10250,12298,12299,10252,12300,12301,10254,12302,12303,10256,12304,12305,10258,12306,12307,10260,10262,10264,10266,10268,10270,10272,10274,10276,10499,10501,10503,10505,10507,10509,10511,10513,10515,12564,10517,12565,12566,10519,12567,12568,10521,12569,12570,10523,12571,12572,10525,12573,12574,10527,12575,12576,10529,12577,12578,10531,12579,12580,10533,12581,9730,9732,9734,9736,9738,9741,9743,9745,9747,9748,9750,9752,9754,9756,9759,9761,9763,9765,9987,9989,9991,9993,9995,9996,9998,10000,10002,10005,10007,10009,10011,10013,10014,10016,10018,10020];
        for(uint16 i =0;i<matrixIndexes.length;i++) {
            winMatrix[matrixIndexes[i]] = 1;
        }
        winFactor1Initialzied = true;
    }

    bool winFactor2Initialzied = false;
    function initWinMatrixFactors2() private {
        require(!winFactor2Initialzied);

        uint16[72] memory matrixIndexes = [11290,11291,11292,11293,11294,11295,11296,11297,11298,11299,11300,11301,11524,11527,11530,11533,11536,11539,11542,11545,11548,11551,11554,11557,10754,10755,11779,10756,10757,10758,11782,10759,10760,10761,11785,10762,10763,11788,10764,10765,11791,11794,11797,11800,11803,11806,11809,11812,12034,12037,12040,12043,11022,12046,11023,11024,11025,12049,11026,11027,11028,12052,11029,11030,11031,12055,11032,11033,12058,12061,12064,12067];
        for(uint16 i =0;i<matrixIndexes.length;i++) {
            winMatrix[matrixIndexes[i]] = 2;
        }
        winFactor2Initialzied = true;
    }

    bool winFactor5Initialzied = false;

    function initWinMatrixFactors5() private {
        require(!winFactor5Initialzied);


        uint16[66] memory matrixIndexes = [37893,37894,37895,37896,37897,37898,38929,38930,38931,38932,38933,38934,39965,39966,39967,39968,39969,39970,38152,38153,38154,38155,38156,38157,39188,39189,39190,39191,39192,39193,40224,40225,40226,40227,40228,40229,38411,38412,38413,38414,38415,38416,39447,39448,39449,39450,39451,39452,37634,37635,37636,37637,37638,37639,38670,38671,38672,38673,38674,38675,39706,39707,39708,39709,39710,39711];

        for(uint16 i =0;i<matrixIndexes.length;i++) {
            winMatrix[matrixIndexes[i]] = 5;
        }
        winFactor5Initialzied =true;
    }

    bool winFactor8Initialzied = false;

    function initWinMatrixFactors8() private {
        require(!winFactor8Initialzied);

        uint16[92] memory matrixIndexes = [28675,28676,28678,28679,29705,29706,29708,29709,30735,30736,30738,30739,31765,31766,31768,31769,32795,32796,32798,32799,33825,33826,33828,33829,28933,28934,28936,28937,29963,29964,29966,29967,30993,30994,30996,30997,32023,32024,32026,32027,33053,33054,33056,33057,28161,28162,28163,28164,29190,29191,29193,29194,30220,30221,30223,30224,31250,31251,31253,31254,32280,32281,32283,32284,33310,33311,33313,33314,28418,28419,28421,28422,29448,29449,29451,29452,30478,30479,30481,30482,31508,31509,31511,31512,32538,32539,32541,32542,33568,33569,33571,33572];
        for(uint16 i =0;i<matrixIndexes.length;i++) {
            winMatrix[matrixIndexes[i]] = 8;
        }
        winFactor8Initialzied=true;
    }

    bool winFactor11Initialzied = false;
    function initWinMatrixFactors11() private {
        require(!winFactor11Initialzied);

        uint16[42] memory matrixIndexes = [34821,34822,34823,35857,35858,35859,36893,36894,36895,34049,34051,34052,35080,35081,35082,36116,36117,36118,37152,37153,37154,34305,34306,34307,35339,35340,35341,36375,36376,36377,37411,37412,37413,34562,34563,34564,35598,35599,35600,36634,36635,36636];
        for(uint16 i =0;i<matrixIndexes.length;i++) {
            winMatrix[matrixIndexes[i]] = 11;
        }
        winFactor11Initialzied =true;
    }

    bool winFactor17Initialzied = false;
    function initWinMatrixFactors17() private {
        require(!winFactor17Initialzied);
        uint16[120] memory matrixIndexes = [13313,14339,13316,14342,15367,16393,15370,16394,17419,17420,22542,22543,18449,18450,23571,19476,23574,19479,20504,24600,20505,24603,21533,25629,21534,25632,26657,26658,27683,27684,13570,14594,13571,14597,15622,15625,16650,17676,16653,17677,22799,22800,18706,18707,23828,19733,23829,19736,24857,20762,24860,20765,21790,25886,21791,26912,25889,26915,27940,27941,12801,12802,13827,13828,14853,15877,14854,15880,16905,16908,22028,17933,23054,22031,17936,23057,18962,18965,24085,19990,24086,19993,25114,21019,25115,21022,26143,27169,26146,27172,13057,13059,14084,15110,14087,15111,16136,17160,16137,17163,22283,22286,23311,18192,19217,23314,18195,19220,20247,24343,20248,24346,25371,21276,25372,21279,26400,26401,27426,27429];
        for(uint16 i =0;i<matrixIndexes.length;i++) {
            winMatrix[matrixIndexes[i]] = 17;
        }
        winFactor17Initialzied=true;
    }

    bool winFactor35Initialzied = false;

    function initWinMatrixFactors35() private {
        require(!winFactor35Initialzied);
        uint16[37] memory matrixIndexes =[1028,2056,3084,4112,5140,6168,7196,8224,9252,257,1285,2313,3341,4369,5397,6425,7453,8481,9509,514,1542,2570,3598,4626,5654,6682,7710,8738,771,1799,2827,3855,4883,5911,6939,7967,8995];
        for(uint16 i =0;i<matrixIndexes.length;i++) {
            winMatrix[matrixIndexes[i]] = 35;
        }
        winFactor35Initialzied=true;
    }

    function initWinMatrixFactors(uint16 winFactor) public onlyDeveloper {
        if(winFactor == 1) {
            initWinMatrixFactors1();
        }
        else if(winFactor == 2) {
            initWinMatrixFactors2();
        }
        else if(winFactor == 5) {
            initWinMatrixFactors5();
        }
        else if(winFactor == 8) {
            initWinMatrixFactors8();
        }
        else if (winFactor == 11) {

            initWinMatrixFactors11();

        }
        else if (winFactor == 17) {
            initWinMatrixFactors17();
        }
        else {
            initWinMatrixFactors35();
        }

    }

    function getMaxTypeBets() public view returns (uint16) {
        return maxTypeBets;
    }

    modifier onlyDeveloper()  {
        require(msg.sender == developer);
        _;
    }


    function getFactor(uint16 bet, uint16 wheelResult) external view returns (uint256) {
        return winMatrix[(bet + 1) * 256 + (wheelResult + 1)];
    }

    function getWinFactor(uint16 index) public view returns(uint8) {
        return winMatrix[index];
    }

    function isReady() public view returns( bool) {

        return winFactor1Initialzied
        && winFactor2Initialzied
        && winFactor5Initialzied
        && winFactor8Initialzied
        && winFactor11Initialzied
        && winFactor17Initialzied
        && winFactor35Initialzied;
    }

    function() external {
        revert();
    }
}
