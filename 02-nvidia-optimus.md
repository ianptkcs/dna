# NVIDIA + Optimus no Arch (notebook Clevo, RTX 4050 + Intel iGPU)

Esta é a parte mais delicada da migração. Objetivo: **reproduzir exatamente o que
já funciona hoje no Ubuntu** (driver 595 open, modeset, suspend/resume, PRIME offload).

## O que está funcionando hoje (referência — `raw/nvidia-modprobe.conf`)

```
options nvidia_drm modeset=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_TemporaryFilePath=/var
blacklist nvidiafb
```
- Driver: **595, open kernel modules**.
- Modo: **PRIME render offload** (iGPU Intel desenha a tela; NVIDIA só nos jogos).
- Serviços ligados: `nvidia-suspend`, `nvidia-resume`, `nvidia-hibernate`, `nvidia-powerd`.

## 1. Pacotes

```bash
# dGPU (open modules — recomendado p/ Ada / RTX 4050) + 32-bit p/ Steam
sudo pacman -S nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-prime
# iGPU Intel
sudo pacman -S mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver
# kernels + headers (LTS = rede de segurança contra quebra em update)
sudo pacman -S linux linux-headers linux-lts linux-lts-headers
```

> **Por que `nvidia-open-dkms`**: a partir da série 560 a NVIDIA recomenda os módulos
> abertos pra GPUs Turing+ (sua Ada se encaixa). `-dkms` recompila o módulo a cada
> kernel novo — essencial num rolling release. Você JÁ usa open modules hoje.

## 2. Replicar os parâmetros do módulo

`/etc/modprobe.d/nvidia.conf`:
```
options nvidia_drm modeset=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_TemporaryFilePath=/var
```
`NVreg_PreserveVideoMemoryAllocations=1` é o que faz **suspend/resume não corromper**
a tela — crítico em notebook. Não pule.

## 3. mkinitcpio (carregar os módulos cedo)

Em `/etc/mkinitcpio.conf`, no `MODULES`:
```
MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
```
Depois: `sudo mkinitcpio -P`.
Com `nvidia-open-dkms` + esses módulos no initramfs, você pode dispensar o
parâmetro de kernel; mas pode também adicionar `nvidia_drm.modeset=1` no GRUB
por garantia (ver passo 4).

## 4. GRUB (você já usa GRUB EFI)

Em `/etc/default/grub`, `GRUB_CMDLINE_LINUX_DEFAULT`, opcionalmente:
```
... nvidia_drm.modeset=1
```
Depois: `sudo grub-mkconfig -o /boot/grub/grub.cfg`.

## 5. Serviços de energia/suspend (habilitar — laptop)

```bash
sudo systemctl enable nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service
sudo systemctl enable nvidia-powerd.service   # Dynamic Boost (perf no jogo)
```

## 6. ⚠️ DECISÃO: PRIME offload vs dGPU-only

### Opção A — PRIME render offload (o que você usa hoje; recomendado p/ começar)
iGPU desenha a tela, jogos rodam na NVIDIA sob demanda. Melhor bateria.
- `nvidia-prime` dá o comando `prime-run`.
- **Steam**: opções de inicialização do jogo → `prime-run %command%`
- **Lutris**: por jogo, ativar "Use discrete graphics" (seta as env vars abaixo).
- **Manual**: `prime-run <app>` ou
  `__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia <app>`
- niri sobe sobre o iGPU normalmente; nada especial além do acima.

### Opção B — dGPU-only (só se o BIOS do Clevo tiver MUX / "Discrete")
Tudo na NVIDIA. Melhor desempenho/menos atrito no Wayland, **pior bateria**.
- Trocar no BIOS pra "Discrete only" (verificar se o Clevo "LUNAR" oferece).
- Sem iGPU, não precisa de `prime-run`; tudo já usa a NVIDIA.
- Pra niri, garantir que o KMS da NVIDIA está ativo (passos 2–3).

> **Como checar agora, antes de migrar**: reiniciar, entrar no BIOS/Setup do Clevo
> e procurar por "Graphics mode / MUX / MSHYBRID / Discrete". Anotar aqui:
>
> - [ ] BIOS tem MUX? __________________________________

## 7. niri em híbrido — atenção

niri renderiza na GPU primária. No modo offload (A), isso é o iGPU Intel — é o
cenário que você já roda hoje, então deve subir igual. Se houver tela preta/glitch
ao subir o niri pós-migração, os suspeitos são, nesta ordem:
1. módulos NVIDIA não entraram no initramfs (passo 3),
2. `modeset=1` faltando (passo 2/4),
3. faltou `nvidia-powerd`/serviços de suspend.

## 8. Validação pós-instalação

```bash
nvidia-smi                  # driver detecta a GPU
prime-run glxinfo | grep "OpenGL renderer"   # deve mostrar "NVIDIA ... RTX 4050"
glxinfo | grep "OpenGL renderer"             # sem prime-run → deve mostrar "Intel"
```
Se os dois acima batem (Intel por padrão, NVIDIA via prime-run), o Optimus está ok.

## Risco honesto (rolling release)

Update de kernel pode chegar antes do módulo NVIDIA compilar. Mitigações já embutidas
acima: `-dkms` (recompila) + `linux-lts` (kernel reserva pra bootar se o principal
quebrar). Boa prática: não rodar `pacman -Syu` 5 min antes de algo importante e ler o
[Arch news](https://archlinux.org/news/) antes de updates grandes.
