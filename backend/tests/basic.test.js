// Базовый тест для CI/CD
// Убедимся что jest работает и проект корректно настроен

describe('StudX Backend', () => {
  test('Environment is set up correctly', () => {
    expect(true).toBe(true);
  });

  test('Node version is compatible', () => {
    const nodeVersion = process.version;
    const majorVersion = parseInt(nodeVersion.split('.')[0].replace('v', ''));
    expect(majorVersion).toBeGreaterThanOrEqual(18);
  });
});
