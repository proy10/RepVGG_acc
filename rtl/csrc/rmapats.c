// file = 0; split type = patterns; threshold = 100000; total count = 0.
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "rmapats.h"

scalar dummyScalar;
scalar fScalarIsForced=0;
scalar fScalarIsReleased=0;
scalar fScalarHasChanged=0;
scalar fForceFromNonRoot=0;
scalar fNettypeIsForced=0;
scalar fNettypeIsReleased=0;
void  hsG_0 (struct dummyq_struct * I1093, EBLK  * I1094, U  I651);
void  hsG_0 (struct dummyq_struct * I1093, EBLK  * I1094, U  I651)
{
    U  I1337;
    U  I1338;
    U  I1339;
    struct futq * I1340;
    I1337 = ((U )vcs_clocks) + I651;
    I1339 = I1337 & ((1 << fHashTableSize) - 1);
    I1094->I697 = (EBLK  *)(-1);
    I1094->I701 = I1337;
    if (I1337 < (U )vcs_clocks) {
        I1338 = ((U  *)&vcs_clocks)[1];
        sched_millenium(I1093, I1094, I1338 + 1, I1337);
    }
    else if ((peblkFutQ1Head != ((void *)0)) && (I651 == 1)) {
        I1094->I702 = (struct eblk *)peblkFutQ1Tail;
        peblkFutQ1Tail->I697 = I1094;
        peblkFutQ1Tail = I1094;
    }
    else if ((I1340 = I1093->I1053[I1339].I714)) {
        I1094->I702 = (struct eblk *)I1340->I713;
        I1340->I713->I697 = (RP )I1094;
        I1340->I713 = (RmaEblk  *)I1094;
    }
    else {
        sched_hsopt(I1093, I1094, I1337);
    }
}
void  hsM_27_0__simv_daidir (UB  * pcode, vec32  * I925, U  I851)
{
    UB  * I1391;
    typedef
    UB
     * TermTypePtr;
    U  I1182;
    U  I1138;
    TermTypePtr  I1141;
    U  I1180;
    vec32  * I1174;
    I1141 = (TermTypePtr )pcode;
    I1182 = *I1141;
    I1141 -= I1182;
    I1138 = 2U;
    pcode = (UB  *)(I1141 + I1138);
    pcode = (UB  *)(((UP )(pcode + 0) + 3U) & ~3LU);
    I1180 = (1 + (((I851) - 1) / 32));
    I1174 = (vec32  *)(pcode + 0);
    {
        U  I1128;
        vec32  * I1143 = I1174 + I1182 * I1180;
        I1128 = 0;
        for (; I1128 < I1180; I1128++) {
            if (I925[I1128].I1 != I1143[I1128].I1 || I925[I1128].I2 != I1143[I1128].I2) {
                break ;
            }
        }
        if (I1128 == I1180) {
            return  ;
        }
        for (; I1128 < I1180; I1128++) {
            I1143[I1128].I1 = I925[I1128].I1;
            I1143[I1128].I2 = I925[I1128].I2;
        }
    }
    I925 = (vec32  *)(I1174 + I1138 * I1180);
    rmaEvalWunionW(I925, I1174, I851, I1138);
    pcode += ((I1138 + 1) * I1180 * sizeof(vec32 ));
    pcode = (UB  *)(((UP )(pcode + 0) + 7U) & ~7LU);
    I851 = *(U  *)((pcode + 0));
    {
        struct dummyq_struct * I1093;
        EBLK  * I1094;
        I1093 = (struct dummyq_struct *)&vcs_clocks;
        {
            RmaEblk  * I1094 = (RmaEblk  *)(pcode + 8);
            vec32  * I1355 = (vec32  *)((pcode + 48));
            if (rmaChangeCheckAndUpdateW(I1355, I925, I851)) {
                if (!(I1094->I697)) {
                    I1093->I1048->I697 = (EBLK  *)I1094;
                    I1093->I1048 = (EBLK  *)I1094;
                }
            }
        }
    }
}
void  hsM_27_9__simv_daidir (UB  * pcode, vec32  * I925)
{
    U  I851;
    I851 = *(U  *)((pcode + 0) - sizeof(RP ));
    I925 = (vec32  *)(pcode + 40);
    pcode = ((UB  *)I925) + sizeof(vec32 ) * (1 + (((I851) - 1) / 32));
    pcode = (UB  *)(((UP )(pcode + 0) + 7U) & ~7LU);
    I851 = *(U  *)((pcode + 0));
    U  I1206;
    vec32  * I1185 = 0;
    {
        U  I1180 = (1 + (((I851) - 1) / 32));
        pcode += 4;
        pcode = (UB  *)((((RP )pcode + 0) + 3) & (~3));
        I1185 = (vec32  *)((pcode + 0));
        pcode += (I1180 * sizeof(vec32 ));
        rmaUpdateW(I1185, I925, I851);
    }
    {
        pcode = (UB  *)((((RP )pcode + 0) + 7) & (~7));
        ((void)0);
        {
            RP  * I691 = (RP  *)(pcode + 0);
            RP  I1274;
            I1274 = *I691;
            if (I1274) {
                hsimDispatchCbkMemOptNoDynElabVector(I691, I925, 2, I851);
            }
        }
    }
    {
        RmaRootForceCbkCg  * I1260;
    }
    {
        void * I1381 = I925;
        pcode = (UB  *)((((RP )pcode + 16) + 7) & (~7));
        {
            (*(FPLSELV  *)((pcode + 0) + 8U))(*(UB  **)(pcode + 16), (vec32  *)I1381, *(U  *)(pcode + 0), *(U  *)(pcode + 24));
            I1381 = (void *)I925;
        }
    }
}
void  hsM_29_0__simv_daidir (UB  * pcode, vec32  * I925, U  I851)
{
    UB  * I1391;
    typedef
    UB
     * TermTypePtr;
    U  I1182;
    U  I1138;
    TermTypePtr  I1141;
    U  I1180;
    vec32  * I1174;
    I1141 = (TermTypePtr )pcode;
    I1182 = *I1141;
    I1141 -= I1182;
    I1138 = *(I1141 - 1);
    pcode = (UB  *)(I1141 + I1138);
    pcode = (UB  *)(((UP )(pcode + 0) + 3U) & ~3LU);
    I1180 = (1 + (((I851) - 1) / 32));
    I1174 = (vec32  *)(pcode + 0);
    {
        U  I1128;
        vec32  * I1143 = I1174 + I1182 * I1180;
        I1128 = 0;
        for (; I1128 < I1180; I1128++) {
            if (I925[I1128].I1 != I1143[I1128].I1 || I925[I1128].I2 != I1143[I1128].I2) {
                break ;
            }
        }
        if (I1128 == I1180) {
            return  ;
        }
        for (; I1128 < I1180; I1128++) {
            I1143[I1128].I1 = I925[I1128].I1;
            I1143[I1128].I2 = I925[I1128].I2;
        }
    }
    I925 = (vec32  *)(I1174 + I1138 * I1180);
    rmaEvalWunionW(I925, I1174, I851, I1138);
    pcode += ((I1138 + 1) * I1180 * sizeof(vec32 ));
    pcode = (UB  *)(((UP )(pcode + 0) + 7U) & ~7LU);
    I851 = *(U  *)((pcode + 0));
    {
        struct dummyq_struct * I1093;
        EBLK  * I1094;
        I1093 = (struct dummyq_struct *)&vcs_clocks;
        {
            RmaEblk  * I1094 = (RmaEblk  *)(pcode + 8);
            vec32  * I1355 = (vec32  *)((pcode + 48));
            if (rmaChangeCheckAndUpdateW(I1355, I925, I851)) {
                if (!(I1094->I697)) {
                    I1093->I1048->I697 = (EBLK  *)I1094;
                    I1093->I1048 = (EBLK  *)I1094;
                }
            }
        }
    }
}
void  hsM_29_9__simv_daidir (UB  * pcode, vec32  * I925)
{
    U  I851;
    I851 = *(U  *)((pcode + 0) - sizeof(RP ));
    I925 = (vec32  *)(pcode + 40);
    pcode = ((UB  *)I925) + sizeof(vec32 ) * (1 + (((I851) - 1) / 32));
    pcode = (UB  *)(((UP )(pcode + 0) + 7U) & ~7LU);
    I851 = *(U  *)((pcode + 0));
    U  I1206;
    vec32  * I1185 = 0;
    {
        U  I1180 = (1 + (((I851) - 1) / 32));
        pcode += 4;
        pcode = (UB  *)((((RP )pcode + 0) + 3) & (~3));
        I1185 = (vec32  *)((pcode + 0));
        pcode += (I1180 * sizeof(vec32 ));
        rmaUpdateW(I1185, I925, I851);
    }
    {
        pcode = (UB  *)((((RP )pcode + 0) + 7) & (~7));
        ((void)0);
        {
            RP  * I691 = (RP  *)(pcode + 0);
            RP  I1274;
            I1274 = *I691;
            if (I1274) {
                hsimDispatchCbkMemOptNoDynElabVector(I691, I925, 2, I851);
            }
        }
    }
    {
        RmaRootForceCbkCg  * I1260;
    }
    {
        void * I1381 = I925;
        pcode = (UB  *)((((RP )pcode + 16) + 7) & (~7));
        {
            (*(FPLSELV  *)((pcode + 0) + 8U))(*(UB  **)(pcode + 16), (vec32  *)I1381, *(U  *)(pcode + 0), *(U  *)(pcode + 24));
            I1381 = (void *)I925;
        }
    }
}
#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif
