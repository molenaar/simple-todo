# BMad Agent & Model Recommendations

## 🎯 Complete BMad Method Integration Guide

This document provides the definitive guide for using BMad agents with optimal AI model selections based on your available VS Code models and cost optimization strategy.

## 📊 Complete BMad Agent Configuration

### Core BMad Method Agents

| Agent | Icon | Name | Role | Primary Model | Alternative | Cost | Specialization |
|-------|------|------|------|---------------|-------------|------|----------------|
| **BMad Master** | 🧙 | BMad Master | Universal Task Executor | **GPT-4.1** | GPT-4o | 0x (Free) | Execute any BMad task across all domains |
| **Analyst** | 📊 | Mary | Business Analyst | **Claude Sonnet 4** | GPT-4.1 | 1x (Standard) | Market research, competitive analysis, brainstorming |
| **Architect** | 🏗️ | Winston | System Architect | **GPT-4.1** | GPT-4 | 0x (Free) | System design, architecture docs, Mermaid diagrams |
| **BMad Orchestrator** | 🎭 | BMad Orchestrator | Workflow Coordinator | **GPT-4.1** | Claude Sonnet 4 | 0x (Free) | Multi-agent coordination, role switching |
| **Dev** | 💻 | James | Full Stack Developer | **GPT-4.1** | GPT-4o | 0x (Free) | Code implementation, debugging, refactoring |
| **PM** | 📋 | John | Product Manager | **GPT-4.1** | Claude Sonnet 4 | 0x (Free) | PRDs, product strategy, roadmap planning |
| **PO** | 📝 | Sarah | Product Owner | **GPT-4.1** | GPT-4o | 0x (Free) | Backlog management, story refinement, acceptance criteria |
| **QA** | 🧪 | Quinn | Test Architect & Quality Advisor | **Claude Sonnet 4** | GPT-4.1 | 1x (Standard) | Test architecture, quality gates, code improvement |
| **SM** | 🏃 | Bob | Scrum Master | **GPT-4o mini** | GPT-4.1 | 0x (Free) | Story creation, epic management, agile process |
| **UX Expert** | 🎨 | Sally | UX Expert | **Claude Sonnet 4** | GPT-4.1 | 1x (Standard) | UI/UX design, wireframes, user experience |

### BMad Commands by Agent and Optimal Models

| Agent | Key Commands | Best Model | Cost | Why This Model |
|-------|-------------|------------|------|----------------|
| **BMad Master** 🧙 | `*help`, `*create-doc`, `*task`, `*execute-checklist` | **GPT-4.1** | 0x | Universal capabilities, latest free model |
| **Analyst** 📊 | `*brainstorm`, `*create-competitor-analysis`, `*elicit` | **Claude Sonnet 4** | 1x | Superior analysis and research capabilities |
| **Architect** 🏗️ | `*create-full-stack-architecture`, `*document-project` | **GPT-4.1** | 0x | Complex reasoning for architecture, free |
| **Dev** 💻 | `*develop-story`, `*run-tests`, `*explain` | **GPT-4.1** | 0x | Code implementation expertise, no cost |
| **PM** 📋 | `*create-prd`, `*create-brownfield-prd`, `*shard-prd` | **GPT-4.1** | 0x | Document creation and strategy, free |
| **PO** 📝 | `*create-story`, `*validate-story-draft` | **GPT-4o mini** | 0x | Efficient for structured tasks |
| **QA** 🧪 | `*review`, `*gate`, `*test-design` | **Claude Sonnet 4** | 1x | Deep analysis for quality assessment |
| **SM** 🏃 | `*draft`, `*story-checklist` | **GPT-4o mini** | 0x | Quick, structured story creation |
| **UX Expert** 🎨 | `*create-front-end-spec`, `*generate-ui-prompt` | **Claude Sonnet 4** | 1x | Creative and detailed design work |

## 🔄 BMad Development Workflow Integration

### Phase-Based BMad Agent Usage

| Development Phase | BMad Agent | VS Code Chat Mode | Model Choice | Cost | Workflow |
|------------------|------------|------------------|--------------|------|----------|
| **Planning & Strategy** | **PM** 📋 → **Architect** 🏗️ | `architecture-planning` | **GPT-4.1** | Free | Create PRD → Design architecture |
| **Research & Analysis** | **Analyst** 📊 | `prototype-development` | **Claude Sonnet 4** | 1x | Market research, competitive analysis |
| **Story Creation** | **SM** 🏃 → **PO** 📝 | `typescript-development` | **GPT-4o mini** | Free | Draft stories → Refine acceptance criteria |
| **Implementation** | **Dev** 💻 | `typescript-development` | **GPT-4.1** | Free | Code implementation and debugging |
| **Quality Assurance** | **QA** 🧪 | `comprehensive-testing` | **Claude Sonnet 4** | 1x | Comprehensive quality assessment |
| **UX/UI Design** | **UX Expert** 🎨 | `frontend-design-review` | **Claude Sonnet 4** | 1x | Design specifications and prototypes |
| **Orchestration** | **BMad Orchestrator** 🎭 | Any phase-appropriate | **GPT-4.1** | Free | Coordinate multi-agent workflows |

### Model Selection Strategy

#### Same Cost = Use Highest Version
When models have identical cost multipliers, always choose the highest version number:

- **Claude Sonnet 3.5/3.7/4.0** → Always use **Claude Sonnet 4**
- **o3-mini vs o4-mini** → Always use **o4-mini**
- **GPT-4 vs GPT-4.1** → Always use **GPT-4.1**

#### Cost-Optimized Task Distribution

| Task Category | Best BMad Agent | Optimal Model | Cost | Reasoning |
|---------------|----------------|---------------|------|-----------|
| **Quick Tasks & Checklists** | BMad Master, SM, PO | **GPT-4o mini** | Free | Efficient for structured work |
| **Document Creation** | BMad Master, PM, Architect | **GPT-4.1** | Free | Excellent writing, complex reasoning |
| **Code Implementation** | Dev | **GPT-4.1** | Free | Latest capabilities for development |
| **Deep Analysis** | Analyst, QA | **Claude Sonnet 4** | 1x | Superior analytical capabilities |
| **Creative Design** | UX Expert | **Claude Sonnet 4** | 1x | Best for creative and detailed work |
| **Architecture Planning** | Architect | **GPT-4.1** | Free | Complex reasoning without cost |
| **Universal Execution** | BMad Master | **GPT-4.1** | Free | Handle any BMad task efficiently |

## 💰 Cost Optimization Strategy

### Daily Budget Allocation

**Free Tier Strategy (85% of work):**
- **BMad Master** + **GPT-4.1** → Universal task execution
- **Dev** + **GPT-4.1** → Code implementation  
- **PM/Architect** + **GPT-4.1** → Planning and architecture
- **SM/PO** + **GPT-4o mini** → Quick story management

**Premium Strategy (15% of work):**
- **Analyst** + **Claude Sonnet 4** → Deep research and analysis
- **QA** + **Claude Sonnet 4** → Comprehensive quality assessment
- **UX Expert** + **Claude Sonnet 4** → Creative design work

### Projected Daily Costs
- **85% FREE** using GPT-4.1 and GPT-4o mini
- **15% Standard Cost (1x)** using Claude Sonnet 4 for specialized analysis
- **Total: $1-3 per day** depending on usage intensity

## 🎯 Quick Agent Selection Guide

### By Task Type
- **Planning?** → Architect 🏗️ + GPT-4.1 (Free)
- **Research?** → Analyst 📊 + Claude Sonnet 4 (1x)
- **Coding?** → Dev 💻 + GPT-4.1 (Free)  
- **Stories?** → SM 🏃 + GPT-4o mini (Free)
- **Testing?** → QA 🧪 + Claude Sonnet 4 (1x)
- **Design?** → UX Expert 🎨 + Claude Sonnet 4 (1x)
- **Anything?** → BMad Master 🧙 + GPT-4.1 (Free)

### By Development Phase
1. **Requirements** → PM 📋 (GPT-4.1)
2. **Architecture** → Architect 🏗️ (GPT-4.1)
3. **Research** → Analyst 📊 (Claude Sonnet 4)
4. **Stories** → SM 🏃 → PO 📝 (GPT-4o mini)
5. **Development** → Dev 💻 (GPT-4.1)
6. **Quality** → QA 🧪 (Claude Sonnet 4)
7. **Design** → UX Expert 🎨 (Claude Sonnet 4)

## 🔧 BMad Integration with VS Code Chat Modes

### Hybrid Approach: BMad Agents + VS Code Chat Modes

| VS Code Chat Mode | Compatible BMad Agents | Recommended Workflow |
|------------------|----------------------|---------------------|
| `architecture-planning` | **Architect** 🏗️, PM 📋 | Use for system design and PRD creation |
| `prototype-development` | **Dev** 💻, UX Expert 🎨 | Use for rapid iteration and UI prototypes |
| `typescript-development` | **Dev** 💻 | Use for implementation with BMad story guidance |
| `frontend-design-review` | **QA** 🧪, UX Expert 🎨 | Use for quality assessment and design validation |
| `comprehensive-testing` | **QA** 🧪 | Use for test architecture and quality gates |
| `azure-devops-integration` | **Dev** 💻, Architect 🏗️ | Use for deployment with BMad architectural guidance |
| `code-documentation` | **BMad Master** 🧙 | Use for comprehensive documentation tasks |

### Recommended Integration Pattern

1. **Start with BMad Agent** for structured task execution
2. **Switch to VS Code Chat Mode** for specialized technical implementation
3. **Return to BMad** for quality gates and completion validation

Example Workflow:
```
Architect 🏗️ (*create-full-stack-architecture) 
    ↓
Switch to `architecture-planning` chat mode for Mermaid diagrams
    ↓
Dev 💻 (*develop-story) for implementation
    ↓  
Switch to `typescript-development` for detailed coding
    ↓
QA 🧪 (*review) for quality assessment
```

## 📋 BMad Method Commands Reference

### Universal Commands (All Agents)
- `*help` - Display available commands for current agent
- `*exit` - Exit current agent mode
- `*yolo` - Toggle confirmation mode

### BMad Master 🧙 Commands
- `*create-doc {template}` - Create document from template
- `*task {task}` - Execute any BMad task
- `*execute-checklist {checklist}` - Run quality checklist
- `*kb` - Toggle knowledge base mode
- `*document-project` - Comprehensive project documentation

### Specialist Agent Commands
- **Analyst** 📊: `*brainstorm`, `*elicit`, `*create-competitor-analysis`
- **Architect** 🏗️: `*create-full-stack-architecture`, `*document-project`
- **Dev** 💻: `*develop-story`, `*run-tests`, `*explain`
- **PM** 📋: `*create-prd`, `*create-brownfield-prd`, `*shard-prd`
- **QA** 🧪: `*review`, `*gate`, `*test-design`, `*nfr-assess`
- **UX Expert** 🎨: `*create-front-end-spec`, `*generate-ui-prompt`

## 🚀 Getting Started with BMad Method

### 1. Choose Your Agent
Select based on your current task:
- **New project?** Start with **PM** 📋 or **Analyst** 📊
- **Have requirements?** Use **Architect** 🏗️
- **Ready to code?** Use **Dev** 💻
- **Need everything?** Use **BMad Master** 🧙

### 2. Select Optimal Model
- **Free tasks:** GPT-4.1 or GPT-4o mini
- **Analysis tasks:** Claude Sonnet 4
- **Quick tasks:** GPT-4o mini

### 3. Execute BMad Workflow
1. Type `*help` to see available commands
2. Execute tasks using `*` prefix commands
3. Switch agents as needed with BMad Orchestrator 🎭
4. Use VS Code chat modes for specialized technical work

### 4. Quality Gates
- Use **QA** 🧪 agent for quality assessment
- Run `*execute-checklist` for validation
- Document results with **BMad Master** 🧙

## 💡 Best Practices

### Cost Optimization
- Use free models (GPT-4.1, GPT-4o mini) for 85% of work
- Reserve Claude Sonnet 4 for analysis, QA, and design tasks
- Monitor daily usage and adjust strategy as needed

### Workflow Efficiency
- Start each project phase with appropriate BMad agent
- Use structured commands (`*`) for consistent results
- Switch to VS Code chat modes for technical deep-dives
- Return to BMad for documentation and quality gates

### Quality Assurance
- Always run quality checklists before completion
- Use **QA** 🧪 agent for comprehensive assessment
- Document architectural decisions with **Architect** 🏗️
- Maintain consistency across all project artifacts

## 🔄 Continuous Improvement

### Regular Reviews
- Weekly cost analysis of model usage
- Monthly workflow optimization review
- Quarterly BMad agent effectiveness assessment
- Document lessons learned and update processes

---

**Remember**: BMad Method provides structured, repeatable workflows with clear quality gates. Combined with optimal model selection, this approach maximizes value while minimizing costs.

**🎯 Key Success Factor**: Always use `*` prefix commands with BMad agents for consistent, high-quality results.
