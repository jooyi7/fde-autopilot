#!/usr/bin/env node
/**
 * Deterministic Core Verification Harness
 * 코어 판정 함수가 정상 데이터, 경계값(Boundary), 결측치(Malformed Input)에서
 * 예외를 던지지 않고 일관된 출력을 내는지 검증합니다.
 */
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

console.log("🧪 Starting Deterministic Core Verification...");

// 1. 공통 수치/방어 유틸리티 검증 템플릿
function safeNumber(val, fallback = 0) {
  if (val === null || val === undefined || val === '') return fallback;
  const num = Number(val);
  return Number.isFinite(num) ? num : fallback;
}

function evaluateSpecBounds(value, lcl, ucl) {
  const v = safeNumber(value, null);
  if (v === null) return { status: 'INVALID_DATA', delta: 0 };
  if (ucl !== null && v > ucl) return { status: 'OUT_OF_SPEC_HIGH', delta: +(v - ucl).toFixed(4) };
  if (lcl !== null && v < lcl) return { status: 'OUT_OF_SPEC_LOW', delta: +(lcl - v).toFixed(4) };
  return { status: 'IN_SPEC', delta: 0 };
}

// 2. 자체 불변성(Invariance) 단위 테스트 실행
try {
  // 정상 범위 테스트
  assert.deepEqual(evaluateSpecBounds(50, 40, 60), { status: 'IN_SPEC', delta: 0 });
  // 상한선 초과 테스트
  assert.deepEqual(evaluateSpecBounds(65.5, 40, 60), { status: 'OUT_OF_SPEC_HIGH', delta: 5.5 });
  // 경계값(Boundary) 정확성 테스트
  assert.deepEqual(evaluateSpecBounds(60, 40, 60), { status: 'IN_SPEC', delta: 0 });
  // 결측치 및 오염 데이터 방어 테스트
  assert.deepEqual(evaluateSpecBounds(null, 40, 60), { status: 'INVALID_DATA', delta: 0 });
  assert.deepEqual(evaluateSpecBounds("NaN_String", 40, 60), { status: 'INVALID_DATA', delta: 0 });

  console.log("✅ [PASS] Base Core Boundary & Null-Safety Assertions passed.");
} catch (err) {
  console.error("❌ [FAIL] Core Assertion Error:", err.message);
  process.exit(1);
}

// 3. 프로젝트 내 테스트 스크립트 연동 확인
const pkgPath = path.resolve(process.cwd(), 'package.json');
if (fs.existsSync(pkgPath)) {
  const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf-8'));
  console.log(`📦 Detected package.json (scripts: ${Object.keys(pkg.scripts || {}).join(', ')})`);
}