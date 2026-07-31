# Contribuindo com o TabelaOS

Obrigado pelo interesse. Antes de abrir um PR, dá uma olhada no `README.md`
pra entender o que o projeto é (instalador Arch Linux estilo Omarchy pro
stack niri + DankMaterialShell) e o que já foi decidido.

## Reportando bugs / sugerindo features

Abra uma [issue](../../issues/new/choose) usando o template apropriado.

## Enviando um PR

1. Fork o repositório.
2. Crie uma branch a partir de `main`.
3. Rode a suite de testes localmente antes de abrir o PR:
   ```bash
   ./test/run.sh
   ```
4. Se a mudança tocar `install/`, `iso/` ou qualquer script de instalação,
   teste num QEMU antes de testar em hardware real — é a convenção que o
   próprio projeto segue (ver `iso/` e a suite `qemu-test/`). Só valide em
   hardware real depois de já ter passado pelo QEMU.
5. Abra o PR usando o template — descreva o quê e o porquê da mudança.
6. PRs que tocam particionamento de disco, LUKS2 ou qualquer script
   destrutivo (que apaga/formata disco) recebem revisão extra — são as
   partes genuinamente arriscadas de um instalador.

## Licença

Ao contribuir, você concorda que sua contribuição será licenciada sob a
[AGPL-3.0](LICENSE), a mesma licença do projeto.

## Código de conduta

Seja respeitoso. Críticas técnicas são bem-vindas; ataques pessoais não.
