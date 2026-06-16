# Day 14 - Reflection
## Evaluation Report & Failure Analysis

**Student:** Vu Hai Tuan  
**Student ID:** 2353280  
**Domain:** AI/RAG Evaluation Assistant

---

## 1. Benchmark Results Summary

**Overall pass rate:** 50%

**Average scores:**

| Metric | Average | Min | Max | Std Dev |
|--------|---------|-----|-----|---------|
| Faithfulness | 0.49 | 0.00 | 1.00 | 0.31 |
| Relevance | 0.57 | 0.00 | 1.00 | 0.30 |
| Completeness | 0.42 | 0.00 | 1.00 | 0.29 |
| Overall Score | 0.49 | 0.00 | 0.76 | 0.24 |

**Score interpretation across the 60 primary metric cells:**

- Good (0.8-1.0): 9
- Needs Work (0.6-0.8): 18
- Significant Issues (<0.6): 33

**Failure type distribution:**

| Failure Type | Count | Percentage of Failures |
|--------------|-------|------------------------|
| hallucination | 5 | 50% |
| off_topic | 3 | 30% |
| irrelevant | 1 | 10% |
| incomplete | 1 | 10% |
| refusal | 0 | 0% |

---

## 2. Top 3 Worst Failures - 5 Whys Analysis

### Failure 1

**Question:** How would you evaluate a RAG bot when documents may be stale?

**Agent Answer:** Run a weekly human review.

**Scores:** Faithfulness: 0.00 | Relevance: 0.00 | Completeness: 0.00 | Overall: 0.00

**5 Whys Analysis:**

| Level | Question | Answer |
|-------|----------|--------|
| Symptom | What is the issue? | The answer is too generic and misses freshness-sensitive evaluation. |
| Why 1 | Why did it happen? | The answer does not mention stale documents, citation dates, outdated context, or online monitoring. |
| Why 2 | Why did Why 1 happen? | The generation step did not use the domain-specific context. |
| Why 3 | Why did Why 2 happen? | The prompt did not force the answer to cover freshness and source-age checks. |
| Why 4 | What is the root cause? | The evaluation assistant lacks a required checklist for stale-document RAG systems. |

**Root cause from `find_root_cause()`:**

> Multiple issues detected - review full pipeline

**Do I agree? Why?**

Yes. All three scores are zero, so the issue is not isolated to one metric. The answer failed grounding, relevance, and completeness at the same time.

**Proposed fix:**

Add a prompt checklist for stale-document cases: freshness test cases, citation date checks, online monitoring, and failure when retrieved context is outdated.

---

### Failure 2

**Question:** What thresholds would you set for a medical-style high-risk assistant?

**Agent Answer:** Use 0.5 for all metrics so fewer builds fail.

**Scores:** Faithfulness: 0.00 | Relevance: 0.00 | Completeness: 0.14 | Overall: 0.05

**5 Whys Analysis:**

| Level | Question | Answer |
|-------|----------|--------|
| Symptom | What is the issue? | The answer recommends weak thresholds for a high-risk system. |
| Why 1 | Why did it happen? | The model optimized for fewer failed builds instead of safety. |
| Why 2 | Why did Why 1 happen? | The answer ignored the high-risk medical context. |
| Why 3 | Why did Why 2 happen? | The prompt did not distinguish normal domains from high-risk domains. |
| Why 4 | What is the root cause? | Safety-critical threshold policy is missing from the evaluation rubric. |

**Root cause:**

> Multiple issues detected - review full pipeline

**Proposed fix:**

Add domain-risk rules: high-risk assistants require faithfulness >= 0.90, relevance >= 0.85, completeness >= 0.85, and human review for failures.

---

### Failure 3

**Question:** Why cluster failures before fixing them?

**Agent Answer:** Fix every failure one by one without grouping.

**Scores:** Faithfulness: 0.17 | Relevance: 0.00 | Completeness: 0.17 | Overall: 0.11

**5 Whys Analysis:**

| Level | Question | Answer |
|-------|----------|--------|
| Symptom | What is the issue? | The answer recommends the opposite of the expected strategy. |
| Why 1 | Why did it happen? | The response does not explain shared root causes or broad-impact fixes. |
| Why 2 | Why did Why 1 happen? | The model missed the failure-analysis concept in the context. |
| Why 3 | Why did Why 2 happen? | The prompt did not require comparing individual fixes versus clustered fixes. |
| Why 4 | What is the root cause? | The generation step lacks a structured failure-analysis template. |

**Root cause:**

> Answer does not address the question - improve prompt clarity

**Proposed fix:**

Add a few-shot example showing that failures should be grouped by type and root cause before proposing fixes.

---

## 3. Failure Clustering

| Cluster | Root Cause | Failures in Cluster | Priority |
|---------|------------|--------------------:|----------|
| 1 | Grounding/factuality failure in hallucination cases | 5 | High |
| 2 | Intent drift or off-topic answers | 3 | High |
| 3 | Missing required answer components | 2 | Medium |

**If only one cluster can be fixed first, I choose Cluster 1.**

Hallucination is the largest group and the riskiest type. A faithfulness guardrail plus better context usage can improve multiple failed cases at once.

---

## 4. Improvement Log

Output style from `generate_improvement_log()`:

| Failure ID | Type | Root Cause | Suggested Fix | Status |
|------------|------|------------|---------------|--------|
| F001 | off_topic | Answer is missing key information - increase context window or improve generation | Add faithfulness guardrails and require every factual claim to be supported by retrieved context | Open |
| F002 | off_topic | Context is missing or irrelevant - improve retrieval | Improve query routing and reject answers that drift away from the user question | Open |
| F003 | off_topic | Answer does not address the question - improve prompt clarity | Rewrite the system prompt with clearer intent handling and add few-shot examples for direct answers | Open |
| F004 | irrelevant | Answer is missing key information - increase context window or improve generation | Increase context window or retrieve more chunks so generated answers cover all required facts | Open |
| F005 | hallucination | Multiple issues detected - review full pipeline | Review failure and add a targeted benchmark case | Open |

**Improvement suggestions from `generate_improvement_suggestions()`:**

1. Add faithfulness guardrails and require every factual claim to be supported by retrieved context.
2. Improve query routing and reject answers that drift away from the user question.
3. Rewrite the system prompt with clearer intent handling and add few-shot examples for direct answers.

---

## 5. Regression Testing Strategy

### CI/CD Integration

**Question 1: When should `run_regression()` run in production?**

Run it before every merge to main, after every prompt change, after retriever/index changes, and before any demo or deployment.

**Question 2: Is regression threshold 0.05 suitable?**

For this lab domain, 0.05 is suitable. For high-risk domains, I would use a stricter threshold such as 0.02 and require human review.

**Question 3: Block deployment or alert?**

Block deployment for faithfulness regressions and high-risk domains. For low-risk experiments, alerting is acceptable if the system is not user-facing.

**Question 4: Where should eval run in CI/CD?**

```text
Code change -> Unit tests -> Offline eval -> Regression gate -> Deploy
```

The eval pipeline should run after unit tests but before deployment. Failed thresholds should stop the release.

---

## 6. Continuous Improvement Loop

| Priority | Action | Metric to Improve | Expected Impact |
|----------|--------|-------------------|-----------------|
| 1 | Add faithfulness guardrail and citation requirement. | Faithfulness | Reduce hallucination failures. |
| 2 | Add few-shot examples for hard and adversarial cases. | Relevance, Completeness | Improve directness and coverage. |
| 3 | Add reranking and metadata filters for retrieval. | Context Precision | Put relevant chunks before noisy chunks. |

**New benchmark cases for next sprint:**

- A case where retrieved context contains outdated policy information.
- A prompt-injection case hidden inside a retrieved document.
- A paraphrased correct answer with low lexical overlap to test weakness of word-overlap scoring.

---

## 7. Framework Reflection

**Frameworks used in lab:** RAGAS-inspired heuristic and DeepEval-style local rubric

**Bonus artifacts added:**

- `bonus_framework_comparison.py`: compares the two evaluation styles on the same 20-case dataset.
- `ci/evaluate.sh`: runs pytest and the bonus comparison as a CI/CD quality gate.
- `ci/github-actions-evaluation.yml`: optional GitHub Actions template for repositories with workflow permission.
- Custom metrics: `answer_conciseness` and `answer_specificity`.

**Production choice:** RAGAS plus DeepEval.

| Criteria | Reason |
|----------|--------|
| Focus fit | RAGAS covers retrieval and answer-grounding metrics for RAG systems. |
| CI/CD integration | DeepEval works well with pytest-style assertions and quality gates. |
| Team workflow | RAGAS gives metric visibility; DeepEval gives test-style checks for releases. |

The heuristic implementation is useful for learning because it is transparent and easy to test. The local DeepEval-style rubric adds a second viewpoint without needing API keys. In production, I would replace the local rubric with real DeepEval/RAGAS model-backed evaluators, then calibrate scores against human review.
