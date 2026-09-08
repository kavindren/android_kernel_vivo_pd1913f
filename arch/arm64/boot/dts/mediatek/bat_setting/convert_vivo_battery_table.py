#!/usr/bin/env python3
# Convert vivo's stock fuel-gauge OCV tables (vivo_battery0_profile_tN, in
# <percent_consumed  voltage_mV  resistance_mOhm> triples, 101 rows, 5 temp
# bins) into MediaTek GM30 battery0_profile_tN tables
# (<mah  voltage_mV*10  resistance_mOhm*10>, 100 rows, 6 temp bins) for
# pd1913f_battery_table.dtsi.
#
# Usage:  convert_vivo_battery_table.py <stock_decompiled.fdt> [bat_id]
#
# vs the previous hand conversion this one:
#  - resamples 101 -> 100 points by linear interpolation over percent, so the
#    fully-depleted endpoint (3.40 V) is preserved instead of truncated
#  - scales the mah axis to the real per-temp Q_MAX (vivo,bats-qmax) instead
#    of a fixed 0..29760 span, so profile mah and g_Q_MAX agree
#
# GM30 temp bins (mt6768.dts TEMPERATURE_T0..T5): 50 25 10 0 -6 -10 C
# vivo bins assumed (5): -10 0 10 25 50 C  -> t0..t4
#   GM30 T0(50) <- vivo t4      T1(25) <- vivo t3     T2(10) <- vivo t2
#   GM30 T3(0)  <- vivo t1      T4(-6) <- interp(vivo t0,t1 @ -6)
#   GM30 T5(-10)<- vivo t0
import sys, re

VIVO_TEMPS = [-10, 0, 10, 25, 50]          # vivo t0..t4
GM30_TEMPS = [50, 25, 10, 0, -6, -10]       # gm30 t0..t5
ROWS = 100

def parse(fdt, bat_id):
    txt = open(fdt).read()
    prof = []
    for t in range(5):
        m = re.search(rf'vivo_battery{bat_id}_profile_t{t} = <([^>]+)>', txt, re.S)
        v = [int(x, 0) for x in m.group(1).split()]
        prof.append([(v[i], v[i+1], v[i+2]) for i in range(0, len(v), 3)])  # (pct, mV, mOhm)
    m = re.search(r'vivo,bats-qmax = <([^>]+)>', txt)
    q = [int(x, 0) for x in m.group(1).split()]
    # layout: [battery-id][5 vivo temp bins], mAh; take this unit's id
    qmax_fresh = q[bat_id * 5: bat_id * 5 + 5]
    return prof, qmax_fresh

def interp_at(table, pct):
    # table: list of (pct, mV, mOhm) sorted by pct 0..100
    for i in range(len(table) - 1):
        p0, v0, r0 = table[i]
        p1, v1, r1 = table[i+1]
        if p0 <= pct <= p1:
            f = 0 if p1 == p0 else (pct - p0) / (p1 - p0)
            return v0 + f*(v1 - v0), r0 + f*(r1 - r0)
    return table[-1][1], table[-1][2]

def qmax_at(qmax_fresh, temp):
    xs = VIVO_TEMPS
    if temp <= xs[0]:  return qmax_fresh[0]
    if temp >= xs[-1]: return qmax_fresh[-1]
    for i in range(len(xs)-1):
        if xs[i] <= temp <= xs[i+1]:
            f = (temp - xs[i]) / (xs[i+1] - xs[i])
            return qmax_fresh[i] + f*(qmax_fresh[i+1] - qmax_fresh[i])

def vivo_table_for(prof, temp):
    xs = VIVO_TEMPS
    if temp <= xs[0]:  return prof[0]
    if temp >= xs[-1]: return prof[-1]
    for i in range(len(xs)-1):
        if xs[i] <= temp <= xs[i+1]:
            f = (temp - xs[i]) / (xs[i+1] - xs[i])
            a, b = prof[i], prof[i+1]
            return [(a[k][0],
                     a[k][1] + f*(b[k][1]-a[k][1]),
                     a[k][2] + f*(b[k][2]-a[k][2])) for k in range(len(a))]

def emit(prof, qmax_fresh):
    out = []
    for gi, gt in enumerate(GM30_TEMPS):
        tbl = vivo_table_for(prof, gt)
        qm = qmax_at(qmax_fresh, gt)
        out.append(f"\t\t/* battery0_profile_t{gi}: {gt}C  (Qmax {round(qm)} mAh) */")
        out.append(f"\t\tbattery0_profile_t{gi}_num = <{ROWS}>;")
        out.append(f"\t\tbattery0_profile_t{gi}_col = <3>;")
        out.append(f"\t\tbattery0_profile_t{gi} = <")
        rows = []
        for k in range(ROWS):
            pct = k * 100.0 / (ROWS - 1)
            mv, mo = interp_at(tbl, pct)
            # GM30 profile "mah" axis is in 0.1 mAh, and the gauge takes
            # profile[last].mah as Q_MAX (qmax_t_0ma_tb1) when QMAX_SEL is
            # absent -- so the last row must equal real per-temp Qmax*10.
            mah = round(pct * qm / 100.0 * 10.0)
            rows.append(f"{mah} {round(mv)*10} {round(mo)*10}")
        for i in range(0, ROWS, 6):
            out.append("\t\t" + "   ".join(rows[i:i+6]) + ("   " if i+6 < ROWS else ""))
        out.append("\t\t>;\n")
    return "\n".join(out)

if __name__ == "__main__":
    fdt = sys.argv[1] if len(sys.argv) > 1 else "stock_decompiled.fdt"
    bat_id = int(sys.argv[2]) if len(sys.argv) > 2 else 0
    prof, qmax_fresh = parse(fdt, bat_id)
    print(emit(prof, qmax_fresh))
