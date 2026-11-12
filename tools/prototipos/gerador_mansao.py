"""Prototipo do gerador da mansao do Invokyr.

Grade de celulas de 11 x 11 studs (corredor com 9 por dentro + 2 paredes de 1).
Celula (i, j) tem o centro em X = 11*i, Z = 11*j (mundo do Roblox, norte = Z negativo).
O centro (torre + Atrio) e fixo; o resto e gerado a cada sorteio.
"""
import random, math, json, sys
from collections import deque

C = 11.0                    # tamanho da celula em studs
R = 12                      # a grade vai de -R a +R celulas (25 x 25 = 275 studs)
N, L, S, O = (0, -1), (1, 0), (0, 1), (-1, 0)
DIRS = [N, L, S, O]
NOME_DIR = {N: 'N', L: 'L', S: 'S', O: 'O'}

# ---------------------------------------------------------------- acervo de salas
# (nome, largura x profundidade em celulas, tipo). Salas comuns e de desafio.
COMUNS = [
    ('Sala de Jantar', 3, 5), ('Biblioteca', 4, 4), ('Sala de Música', 3, 4), ('Galeria', 3, 5),
    ('Arquivo', 3, 3), ('Cozinha', 3, 4), ('Jardim de Inverno', 4, 4), ('Quarto Principal', 3, 4),
    ('Quarto de Hóspedes', 3, 3), ('Escritório', 3, 3), ('Sala de Bilhar', 3, 4), ('Capela', 3, 5),
    ('Lavanderia', 2, 3), ('Despensa', 2, 2), ('Sala de Costura', 3, 3), ('Berçário', 3, 3),
    ('Sala de Troféus', 3, 4), ('Banheiro', 2, 3), ('Sala de Fumo', 3, 3), ('Rouparia', 2, 2),
]
DESAFIOS = [
    ('Salão da Bailarina', 3, 8), ('Sala dos Canos', 3, 8), ('Adega Alagada', 4, 6), ('Câmara Fria', 3, 7),
]


class Mansao:
    def __init__(self, semente, n_comuns=12, n_desafios=3, dist_min_desafio=22, dist_max_desafio=40):
        self.rng = random.Random(semente)
        self.semente = semente
        self.ocup = {}                      # celula -> 'H' (centro fixo) ou id da sala
        self.salas = []                     # dict(id, nome, tipo, i0, j0, w, h, portas=[(celula_fora, dir_para_dentro)])
        self.saidas_hub = []                # (celula do corredor, direcao para o hub)
        self.n_comuns, self.n_desafios, self.dist_min, self.dist_max = n_comuns, n_desafios, dist_min_desafio, dist_max_desafio
        self._hub()

    # -------------------------------------------------- centro fixo
    def _hub(self):
        for i in range(-1, 2):
            for j in range(-1, 2): self.ocup[(i, j)] = 'H'          # torre: 33 x 33, cobre o octogono de 32,87
            for j in range(-6, -1): self.ocup[(i, j)] = 'H'         # Atrio: 3 x 5 celulas (o Atrio real tem 32 x 48,1)
        for s in (-1, 1):
            for j in (-4, -3): self.ocup[(2 * s, j)] = 'H'          # adaptador da porta lateral do Atrio (porta em Z = -41,09)
        # portas da torre (L, S, O) e as 2 saidas dos adaptadores do Atrio
        self.saidas_hub = [((2, 0), O), ((0, 2), N), ((-2, 0), L), ((3, -4), O), ((-3, -4), L)]

    def livre(self, c): return abs(c[0]) <= R and abs(c[1]) <= R and c not in self.ocup

    # -------------------------------------------------- salas
    def _cabe(self, i0, j0, w, h, margem=1):
        for i in range(i0 - margem, i0 + w + margem):
            for j in range(j0 - margem, j0 + h + margem):
                inside = i0 <= i < i0 + w and j0 <= j < j0 + h
                if inside and not (abs(i) <= R and abs(j) <= R): return False
                if (i, j) in self.ocup: return False
        return True

    def _vagas_porta(self, i0, j0, w, h, tipo):
        """vagas de porta: meio de cada lado (desafio: so as pontas curtas)"""
        v = []
        lados = {N: [(i0 + k, j0) for k in range(w)], S: [(i0 + k, j0 + h - 1) for k in range(w)],
                 O: [(i0, j0 + k) for k in range(h)], L: [(i0 + w - 1, j0 + k) for k in range(h)]}
        for d, cel in lados.items():
            if tipo == 'D' and len(cel) > min(w, h): continue           # desafio: porta so no lado curto
            meio = [cel[len(cel) // 2]] if len(cel) % 2 else [cel[len(cel) // 2 - 1], cel[len(cel) // 2]]
            for c in meio:
                fora = (c[0] + d[0], c[1] + d[1])
                v.append((fora, (-d[0], -d[1])))
        return v

    def _colocar(self, nome, w, h, tipo, tentativas=400, dist_min=0):
        for _ in range(tentativas):
            if self.rng.random() < 0.5: w, h = h, w
            i0 = self.rng.randint(-R, R - w + 1); j0 = self.rng.randint(-R, R - h + 1)
            ci, cj = i0 + (w - 1) / 2, j0 + (h - 1) / 2
            if abs(ci) + abs(cj) < dist_min: continue
            if not self._cabe(i0, j0, w, h): continue
            vagas = [v for v in self._vagas_porta(i0, j0, w, h, tipo) if self.livre(v[0])]
            if not vagas: continue
            if tipo == 'D':
                # desafio: 1 porta so, na ponta virada para o centro
                vagas.sort(key=lambda v: abs(v[0][0]) + abs(v[0][1])); portas = [vagas[0]]
            else:
                self.rng.shuffle(vagas)
                n = min(len(vagas), self.rng.choices([1, 2, 3], weights=[2, 5, 3])[0])
                portas = vagas[:n]
            sid = '%s%d' % (tipo, len(self.salas) + 1)
            for i in range(i0, i0 + w):
                for j in range(j0, j0 + h): self.ocup[(i, j)] = sid
            self.salas.append(dict(id=sid, nome=nome, tipo=tipo, i0=i0, j0=j0, w=w, h=h, portas=portas,
                                   vagas_fechadas=len(self._vagas_porta(i0, j0, w, h, tipo)) - len(portas)))
            return True
        return False

    # -------------------------------------------------- corredores
    def _cavar(self, lig, origem, alvos, ruido=1.6, waypoint=None):
        """caminho com custo aleatorio (corredor que serpenteia) da origem ate a rede existente"""
        import heapq
        def busca(ini, fim_ok):
            custo = {ini: 0}; ant = {ini: None}; h = [(0, self.rng.random(), ini, None)]
            peso = {}
            while h:
                g, _, c, d0 = heapq.heappop(h)
                if fim_ok(c) and c != ini: 
                    cam = []
                    while c is not None: cam.append(c); c = ant[c]
                    return cam[::-1]
                if g > custo.get(c, 1e9): continue
                for d in DIRS:
                    n = (c[0] + d[0], c[1] + d[1])
                    if not (self.livre(n) or n in lig): continue
                    w = peso.setdefault(n, 1 + self.rng.random() * ruido)
                    if d0 is not None and d != d0: w += 0.35          # curva custa um pouco: trechos retos
                    if n in lig: w *= 0.55                            # reaproveitar corredor que ja existe
                    ng = g + w
                    if ng < custo.get(n, 1e9):
                        custo[n] = ng; ant[n] = c; heapq.heappush(h, (ng, self.rng.random(), n, d))
            return None
        trechos = []
        if waypoint is not None:
            c1 = busca(origem, lambda c: c == waypoint)
            if not c1: return False
            trechos.append(c1); origem = waypoint
        c2 = busca(origem, lambda c: c in alvos)
        if not c2: return False
        trechos.append(c2)
        for cam in trechos:
            for a, b in zip(cam, cam[1:]):
                lig.setdefault(a, set()).add(b); lig.setdefault(b, set()).add(a)
            if len(cam) == 1: lig.setdefault(cam[0], set())
        return True

    def _rede(self):
        lig = {}
        saidas = [c for c, _ in self.saidas_hub]
        for c in saidas: lig[c] = set()
        # liga as saidas do centro entre si primeiro (anel em volta do centro)
        for k in range(1, len(saidas)):
            if not self._cavar(lig, saidas[k], set(saidas[:k]) | set(lig)): return None
        # salas comuns, da mais perto para a mais longe
        comuns = sorted([s for s in self.salas if s['tipo'] == 'A'], key=lambda s: abs(s['i0']) + abs(s['j0']))
        for s in comuns:
            for p, _ in s['portas']:
                if p in lig: continue
                if not self._cavar(lig, p, set(lig)): return None
        # desafios: passam por um ponto de desvio longe da porta, para o caminho ser comprido e escondido
        for s in [s for s in self.salas if s['tipo'] == 'D']:
            p = s['portas'][0][0]
            livres = [(i, j) for i in range(-R, R + 1) for j in range(-R, R + 1) if self.livre((i, j)) and (i, j) not in lig
                      and 4 <= abs(i - p[0]) + abs(j - p[1]) <= 9]
            wp = self.rng.choice(livres) if livres else None
            if not self._cavar(lig, p, set(lig), ruido=2.4, waypoint=wp):
                if not self._cavar(lig, p, set(lig)): return None
        return lig

    def _nichos(self, lig, n):
        """becos de exploracao: corredores curtos sem saida, onde podem nascer totens e sustos"""
        feitos = 0
        base = list(lig); self.rng.shuffle(base)
        for c in base:
            if feitos >= n: break
            d = self.rng.choice(DIRS); comp = self.rng.randint(2, 4)
            cam = [c]; ok = True
            for k in range(comp):
                x = (cam[-1][0] + d[0], cam[-1][1] + d[1])
                # nao encostar em outro corredor (senao vira atalho em vez de beco)
                viz = [(x[0] + e[0], x[1] + e[1]) for e in DIRS]
                if not self.livre(x) or x in lig or any(v in lig and v != cam[-1] for v in viz): ok = False; break
                cam.append(x)
                if self.rng.random() < 0.4: d = self.rng.choice([e for e in DIRS if e != (-d[0], -d[1])])
            if ok and len(cam) >= 3:
                for a, b in zip(cam, cam[1:]):
                    lig.setdefault(a, set()).add(b); lig.setdefault(b, set()).add(a)
                feitos += 1
        return feitos

    def _lacos(self, lig, n_lacos):
        """atalhos: liga dois corredores que estao perto no mapa mas longe pelo caminho. Sao as rotas de fuga."""
        feitos, tent = 0, 0
        cels = list(lig)
        while feitos < n_lacos and tent < 300:
            tent += 1
            a = self.rng.choice(cels)
            dist = self._bfs(lig, [a])
            perto = [b for b in cels if 3 <= abs(a[0] - b[0]) + abs(a[1] - b[1]) <= 7 and dist.get(b, 999) >= 16]
            if not perto: continue
            b = self.rng.choice(perto)
            # cava so por celula livre (nao pode reaproveitar corredor, senao nao vira laco)
            import heapq
            h = [(0, a)]; ant = {a: None}; g = {a: 0}; achou = False
            while h:
                cg, c = heapq.heappop(h)
                if c == b: achou = True; break
                for d in DIRS:
                    n = (c[0] + d[0], c[1] + d[1])
                    if n != b and not self.livre(n): continue
                    if n in lig and n != b: continue
                    ng = cg + 1 + self.rng.random() * 0.5
                    if ng < g.get(n, 1e9) and ng < 12: g[n] = ng; ant[n] = c; heapq.heappush(h, (ng, n))
            if not achou: continue
            cam = []; c = b
            while c is not None: cam.append(c); c = ant[c]
            for x, y in zip(cam, cam[1:]):
                lig.setdefault(x, set()).add(y); lig.setdefault(y, set()).add(x)
            cels = list(lig); feitos += 1
        return feitos

    def _faz_quadrado(self, lig, a, b):
        d = (b[0] - a[0], b[1] - a[1]); p = (-d[1], d[0])
        for s in (1, -1):
            a2, b2 = (a[0] + s * p[0], a[1] + s * p[1]), (b[0] + s * p[0], b[1] + s * p[1])
            if a2 in lig and b2 in lig and a2 in lig[a] and b2 in lig[b] and b2 in lig[a2]: return True
        return False

    @staticmethod
    def _bfs(lig, inicios):
        dist = {c: 0 for c in inicios}; q = deque(inicios)
        while q:
            c = q.popleft()
            for n in lig.get(c, ()):
                if n not in dist: dist[n] = dist[c] + 1; q.append(n)
        return dist

    # -------------------------------------------------- tudo
    def gerar(self):
        pool_d = DESAFIOS[:]; self.rng.shuffle(pool_d)
        for nome, w, h in pool_d[:self.n_desafios]:
            if not self._colocar(nome, w, h, 'D', tentativas=3000, dist_min=12): return False
        pool_c = COMUNS[:]; self.rng.shuffle(pool_c)
        postas = 0
        for nome, w, h in pool_c:
            if postas >= self.n_comuns: break
            if self._colocar(nome, w, h, 'A', tentativas=300): postas += 1
        lig = self._rede()
        if lig is None: return False
        self.n_nichos = self._nichos(lig, n=6)
        self.n_lacos = self._lacos(lig, n_lacos=3)
        self.lig = lig
        # distancia andando da torre ate cada porta (em celulas)
        dist = self._bfs(lig, [c for c, _ in self.saidas_hub[:3]])
        self.dist = {}
        for s in self.salas:
            self.dist[s['id']] = min(dist.get(p[0], 999) for p in s['portas'])
        for s in self.salas:
            if s['tipo'] == 'D' and not (self.dist_min <= self.dist[s['id']] <= self.dist_max): return False
        return True

    # -------------------------------------------------- pecas de corredor
    def pecas(self):
        """que peca de corredor vai em cada celula: depende so de para onde ela abre"""
        portas = {p[0]: p[1] for s in self.salas for p in s['portas']}
        portas.update({c: d for c, d in self.saidas_hub})
        out = {}
        for c, viz in self.lig.items():
            ab = {(n[0] - c[0], n[1] - c[1]) for n in viz}
            if c in portas: ab.add(portas[c])
            k = len(ab)
            if k == 1: t = 'Beco'
            elif k == 2: t = 'Reto' if (sum(d[0] for d in ab), sum(d[1] for d in ab)) == (0, 0) else 'Curva'
            elif k == 3: t = 'T'
            else: t = 'Cruz'
            out[c] = (t, ab)
        return out

    def resumo(self):
        pc = self.pecas()
        from collections import Counter
        cont = Counter(t for t, _ in pc.values())
        return dict(semente=self.semente, salas_comuns=sum(1 for s in self.salas if s['tipo'] == 'A'),
                    desafios=[(s['nome'], self.dist[s['id']] * 11) for s in self.salas if s['tipo'] == 'D'],
                    celulas_corredor=len(pc), metros_corredor=round(len(pc) * C * 0.28),
                    pecas=dict(cont), becos_de_exploracao=self.n_nichos, lacos=self.n_lacos,
                    comuns_dist=sorted(self.dist[s['id']] * 11 for s in self.salas if s['tipo'] == 'A'))


def gerar(semente, **kw):
    for t in range(2000):
        m = Mansao(semente * 100000 + t, **kw)
        if m.gerar(): return m
    raise RuntimeError('nao gerou')


if __name__ == '__main__':
    for s in map(int, sys.argv[1:] or [1, 2, 3]):
        m = gerar(s); print(json.dumps(m.resumo(), ensure_ascii=False))
