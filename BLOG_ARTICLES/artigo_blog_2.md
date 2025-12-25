# Cadeia de Suprimentos de Software Segura no Setor Financeiro: Implementando SBOM e Assinatura de Artefatos

## Introdução

O setor financeiro é um alvo principal para ataques cibernéticos, e a segurança da cadeia de suprimentos de software tornou-se uma preocupação crítica após incidentes como SolarWinds. Garantir a integridade e a proveniência do software que utilizamos e entregamos é fundamental. Minha experiência em grandes instituições financeiras como Serasa Experian e Banco Bradesco me proporcionou insights sobre como as práticas de DevSecOps, especificamente a Geração de Lista de Materiais de Software (SBOM) e a Assinatura de Artefatos, são cruciais para construir uma cadeia de suprimentos de software mais resiliente.

Este artigo detalha a importância e a implementação dessas práticas em um ambiente CI/CD, alinhando-se aos mandatos federais como a Ordem Executiva 14028 dos EUA.

## O Cenário de Ameaças: Ataques à Cadeia de Suprimentos de Software

Um ataque à cadeia de suprimentos de software ocorre quando um invasor introduz código malicioso ou vulnerabilidades em componentes de software upstream, que são então distribuídos para usuários finais. Para instituições financeiras, isso pode ter consequências devastadoras, incluindo roubo de dados, interrupção de serviços e danos à reputação.

A Ordem Executiva 14028 dos EUA, "Improving the Nation's Cybersecurity", reconheceu essa ameaça, exigindo que as agências federais e seus fornecedores implementem práticas de segurança da cadeia de suprimentos, como SBOM e assinatura de artefatos.

## A Solução DevSecOps: SBOM e Assinatura de Artefatos

Integramos a geração de SBOM e a assinatura de artefatos diretamente em nossos pipelines de CI/CD para automatizar e aplicar essas salvaguardas.

### 1. Geração de Lista de Materiais de Software (SBOM)

Uma SBOM é como uma lista de ingredientes completa para um produto de software. Ela lista todos os componentes de código aberto e proprietários, suas versões, licenças e quaisquer dependências.

*   **Como Implementamos (Projeto Serasa Experian):**
    *   Utilizamos ferramentas como **Syft** e **Trivy** integradas ao nosso pipeline GitLab CI/CD para analisar os artefatos de construção (imagens de contêiner, pacotes de aplicativos) e gerar SBOMs automaticamente nos formatos SPDX e CycloneDX.
    *   Essas SBOMs eram armazenadas em um registro de artefatos seguro (Artifactory) e associadas aos respectivos artefatos de construção.
    *   **Benefício:** A visibilidade total dos componentes nos permitiu identificar rapidamente vulnerabilidades conhecidas (CVEs) usando ferramentas de Análise de Composição de Software (SCA) e gerenciar riscos de forma proativa.

### 2. Assinatura e Proveniência de Artefatos

A assinatura de artefatos garante a integridade e a autenticidade do software, verificando que ele não foi adulterado desde a sua construção e que veio de uma fonte confiável. A proveniência, por sua vez, rastreia a origem e o histórico do artefato.

*   **Como Implementamos (Projeto Banco Bradesco):**
    *   Integramos **Sigstore/Cosign** em nossos pipelines para assinar digitalmente imagens de contêineres e outros artefatos. As chaves de assinatura eram gerenciadas de forma segura com um KMS (Key Management Service).
    *   Implementamos verificações nos ambientes de implantação que garantiam que **apenas artefatos assinados e verificados** pudessem ser implantados em produção. Isso nos alinhou com a estrutura SLSA (Supply-chain Levels for Software Artifacts).
    *   **Benefício:** Impediu a implantação de software não autorizado ou adulterado, fornecendo uma camada crítica de confiança na cadeia de suprimentos.

### Implementação de Políticas como Código (Policy-as-Code)

Além de SBOM e assinatura, aplicamos o conceito de Políticas como Código usando **Open Policy Agent (OPA)**. Regras foram definidas para, por exemplo, bloquear implantações se um artefato não possuísse uma SBOM ou se sua assinatura não pudesse ser verificada. Isso garantiu que as políticas de segurança fossem aplicadas de forma consistente e automatizada, sem intervenção manual.

## Conclusão

A segurança da cadeia de suprimentos de software é uma batalha contínua, mas a implementação automatizada de SBOM, assinatura de artefatos e políticas como código em pipelines de CI/CD oferece uma defesa robusta. No setor financeiro, onde a confiança e a integridade dos dados são supremas, essas práticas não são apenas "agradáveis de ter", mas são absolutamente essenciais. Elas nos permitem não apenas cumprir os mandatos federais, mas também construir sistemas mais seguros e resilientes que protegem as operações críticas e os dados dos clientes.

---
*Gustavo de Oliveira Ferreira é um especialista em DevSecOps e Cloud com vasta experiência na implementação de práticas de segurança da cadeia de suprimentos de software em ambientes de missão crítica. Ele acredita na automação como o caminho para a conformidade e a segurança escaláveis.*
