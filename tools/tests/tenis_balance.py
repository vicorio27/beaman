"""El equilibrio del torneo, repartido en varios procesos de Godot a la vez (todos contra todos y las
contras), y juntado aquí. Mismos criterios que tools/tests/tenis_roster.gd:
  - nadie gana más del 65% ni menos del 35% de sus partidos
  - la mezcla de golpes de cualquier par difiere en 0.15 o más
  - cada contra le quita 20% o más a su habilidad, y la máquina que la sabe la logra más seguido
Uso (desde la carpeta del proyecto):  python tools/tests/tenis_balance.py [partidos_por_cruce] [procesos]
Sale con código 1 si algo falla."""
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

GODOT = os.path.join("..", "Godot_v4.6.3-stable_win64_console.exe")
MIX_KEYS = ["drive", "slice", "lob", "drop", "underarm", "trick"]
HOW_KEYS = ["deep", "fast", "wide"]
IDS = ["bublikov", "sabalenkova", "monfiz", "yokovich", "moutette", "tiafuego", "sheltron", "kyrgistan", "pecador",
       "fedorer"]


def run(env_extra):
    env = dict(os.environ, **env_extra)
    out = subprocess.run([GODOT, "--headless", "--path", ".", "-s", "tools/tests/tenis_roster.gd"], env=env,
                         capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=3600)
    return out.stdout


def rate(n, procs):
    """Rápido, para ajustar: cada uno contra el parejo ("base")."""
    jobs = [{"TENIS_ONLY": "rate", "TENIS_N": n, "TENIS_IDS": x} for x in IDS]
    with ThreadPoolExecutor(max_workers=procs) as ex:
        outs = list(ex.map(run, jobs))
    rows = []
    for out in outs:
        for line in out.splitlines():
            p = line.split()
            if p[:1] == ["RATE"]:
                rows.append((p[1], int(p[2]) / int(p[3]), int(p[4]) / max(1, int(p[5]))))
    for x, w, pt in sorted(rows, key=lambda r: -r[2]):
        print(f"  {x:12s} partidos {w * 100:3.0f}%   puntos {pt * 100:3.0f}%")


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    if sys.argv[1:2] == ["rate"]:
        rate(sys.argv[2] if len(sys.argv) > 2 else "24", 10)
        return
    n = sys.argv[1] if len(sys.argv) > 1 else "16"
    procs = int(sys.argv[2]) if len(sys.argv) > 2 else 6
    jobs = [{"TENIS_ONLY": "sim", "TENIS_N": n, "TENIS_SHARD": f"{i}/{procs}"} for i in range(procs)]
    with ThreadPoolExecutor(max_workers=procs) as ex:
        outs = list(ex.map(run, jobs))
    wins, played, mix, pairs = {}, {}, {}, []
    for out in outs:
        for line in out.splitlines():
            parts = line.split()
            if parts[:1] == ["PAR"]:
                a, b, wa, nn = parts[1], parts[2], int(parts[3]), int(parts[4])
                pairs.append((a, b, wa, nn))
                for x, w in ((a, wa), (b, nn - wa)):
                    wins[x] = wins.get(x, 0) + w
                    played[x] = played.get(x, 0) + nn
            elif parts[:1] == ["MIX"]:
                m = mix.setdefault(parts[1], [0] * (len(MIX_KEYS) + len(HOW_KEYS) + 1))
                for i, v in enumerate(parts[2:]):
                    m[i] += int(v)
    fails = 0
    print("Cruces:")
    for a, b, wa, nn in sorted(pairs):
        print(f"  {a:12s} {wa:2d} - {nn - wa:2d} {b}")
    print("Cada uno:")
    norm, how = {}, {}
    nk = len(MIX_KEYS)
    for x in sorted(wins, key=lambda k: -wins[k] / played[k]):
        tot = max(1, sum(mix[x][:nk]))
        norm[x] = [v / tot for v in mix[x][:nk]]
        hits = max(1, mix[x][-1])
        how[x] = [v / hits for v in mix[x][nk:nk + len(HOW_KEYS)]]
        golpes = " ".join(f"{k[:3]} {v * 100:2.0f}" for k, v in zip(MIX_KEYS, norm[x]))
        como = " ".join(f"{k} {v * 100:2.0f}" for k, v in zip(["fondo", "duro", "abierto"], how[x]))
        print(f"  {x:12s} gana {wins[x] / played[x] * 100:5.1f}%   {golpes}   | {como}")
    best = max(wins[x] / played[x] for x in wins)
    worst = min(wins[x] / played[x] for x in wins)
    ok = best <= 0.65 and worst >= 0.35
    fails += not ok
    print(("PASS" if ok else "FAIL") + f" nadie gana más del 65% ni menos del 35%  (de {worst * 100:.1f}% a {best * 100:.1f}%)")
    ids = sorted(norm)
    dmin, dpair = 9, ""
    for i in range(len(ids)):
        for j in range(i + 1, len(ids)):
            a, b = ids[i], ids[j]
            # Distintos en algo que se ve: el tipo de golpe, o qué tan al fondo, duro o abierto.
            d = max([sum(abs(u - v) for u, v in zip(norm[a], norm[b])) / 2]
                    + [abs(u - v) for u, v in zip(how[a], how[b])])
            if d < dmin:
                dmin, dpair = d, f"{ids[i]}/{ids[j]}"
    ok = dmin >= 0.15
    fails += not ok
    print(("PASS" if ok else "FAIL") + f" cada uno juega distinto: golpe, fondo, dureza o apertura  (los más parecidos: {dpair} {dmin:.2f})")
    # Las contras: un proceso por tenista.
    ids_all = sorted(wins)
    jobs = [{"TENIS_ONLY": "counter", "TENIS_N": "48", "TENIS_IDS": x} for x in ids_all]
    with ThreadPoolExecutor(max_workers=procs) as ex:
        outs = list(ex.map(run, jobs))
    print("Contras:")
    for out in outs:
        for line in out.splitlines():
            if line.startswith(("PASS", "FAIL")):
                print("  " + line)
                fails += line.startswith("FAIL")
    print(f"\n{fails} fallaron")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
