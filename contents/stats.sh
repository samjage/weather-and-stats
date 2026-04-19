#!/bin/bash

# CPU temp via hwmon (same source as btop)
# Looks for coretemp (Intel), k10temp/zenpower (AMD), cpu-thermal (ARM)
CTEMP=-1
for hwmon in /sys/class/hwmon/hwmon*/; do
    name=$(cat "${hwmon}name" 2>/dev/null)
    if [[ "$name" == "coretemp" || "$name" == "k10temp" || "$name" == "zenpower" || "$name" == "cpu-thermal" ]]; then
        # Prefer Package/Tctl label, otherwise take temp1
        for label_file in "${hwmon}"temp*_label; do
            label=$(cat "$label_file" 2>/dev/null)
            if [[ "$label" == "Package"* || "$label" == "Tctl" || "$label" == "Tccd"* ]]; then
                val=$(cat "${label_file/_label/_input}" 2>/dev/null)
                if [ -n "$val" ] && [ "$val" -gt 0 ]; then CTEMP=$(( val / 1000 )); break 2; fi
            fi
        done
        val=$(cat "${hwmon}temp1_input" 2>/dev/null)
        if [ -n "$val" ] && [ "$val" -gt 0 ]; then CTEMP=$(( val / 1000 )); break; fi
    fi
done
# Fallback: highest thermal_zone reading
if [ "$CTEMP" -lt 0 ]; then
    best=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1)
    [ -n "$best" ] && CTEMP=$(( best / 1000 ))
fi

# Memory usage %
MEM=$(free | awk '/Mem:/{print int($3/$2*100)}')

# Auto-detect most active network interface (excluding loopback)
IFACE=$(awk 'NR>2{gsub(/:$/,"",$1); if($1!="lo") print $1, ($2+0)+($10+0)}' /proc/net/dev \
    | sort -k2 -rn | awk 'NR==1{print $1}')
[ -z "$IFACE" ] && IFACE="lo"

# Helper functions for sampling
get_cpu()  { awk 'NR==1{t=0; for(i=2;i<=NF;i++) t+=$i; print t, $5+$6}' /proc/stat; }
get_net()  { awk -v d="$IFACE:" '$1==d{print $2, $10}' /proc/net/dev; }

# First samples
read T1 I1 < <(get_cpu)
read R1 X1 < <(get_net)

sleep 1

# Second samples
read T2 I2 < <(get_cpu)
read R2 X2 < <(get_net)

# CPU usage %
DT=$(( T2 - T1 ))
CPU=$(( DT > 0 ? (100 * (DT - (I2 - I1))) / DT : 0 ))

# Network KB/s
DOWN=$(( (R2 - R1) / 1024 ))
UP=$(( (X2 - X1) / 1024 ))

echo "$CTEMP $CPU $MEM $DOWN $UP"
