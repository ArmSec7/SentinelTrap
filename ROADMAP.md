# 🗺️ SentinelTrap: Roadmap de Evolução Técnica

Este documento detalha as limitações conhecidas e um plano de melhorias para o **SentinelTrap**, focando em resiliência e performance.

## 🔴 Alta Prioridade (Resiliência)
- [ ] **Arquitetura Fail-Safe:** Reestruturar a lógica de contenção para que o bloqueio no Firewall ocorra *antes* da consulta à API (AbuseIPDB), garantindo proteção mesmo em cenários de instabilidade de rede.
- [ ] **Gerenciamento de Estado:** Implementar um cache local para rastrear IPs já bloqueados, evitando redundância na criação de regras de firewall após reinicializações.

## 🟡 Média Prioridade (Escalabilidade)
- [ ] **Otimização de Firewall:** Substituir a criação de regras individuais por um **Address Group**. O script passará a atualizar uma única regra mestre, reduzindo o overhead do sistema.
- [ ] **Subscrição de Eventos (ETW):** Migrar o método de captura de logs de *Polling* para *Event Subscription*, permitindo resposta em milissegundos com uso de CPU próximo a zero.

## 🟢 Baixa Prioridade (UX & Telemetria)
- [ ] **Módulo de Instalação:** Converter o script em um Módulo PowerShell oficial (.psm1).
- [ ] **Log Audit Trail:** Criar um log local (`C:\Logs\SentinelTrap.log`) para auditoria interna das ações tomadas pelo sistema.

---
*Este roadmap demonstra o compromisso com a melhoria contínua e a segurança defensiva.*
