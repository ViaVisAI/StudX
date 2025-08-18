// Сервис для работы с localStorage
// Обертка с проверками и fallback для безопасной работы

const STORAGE_PREFIX = 'studx_';
const STORAGE_VERSION = 'v1';

// Проверка доступности localStorage
function isStorageAvailable() {
  try {
    const test = '__storage_test__';
    localStorage.setItem(test, test);
    localStorage.removeItem(test);
    return true;
  } catch (e) {
    console.warn('localStorage недоступен:', e);
    return false;
  }
}

// Получение ключа с префиксом
function getKey(key) {
  return `${STORAGE_PREFIX}${STORAGE_VERSION}_${key}`;
}

// Сохранение данных
export function saveToStorage(key, data) {
  if (!isStorageAvailable()) {
    console.warn('Не могу сохранить в localStorage');
    return false;
  }
  
  try {
    const serialized = JSON.stringify({
      data,
      timestamp: Date.now(),
      version: STORAGE_VERSION
    });
    localStorage.setItem(getKey(key), serialized);
    return true;
  } catch (e) {
    console.error('Ошибка сохранения в localStorage:', e);
    // Очистка если переполнен
    if (e.name === 'QuotaExceededError') {
      clearOldData();
    }
    return false;
  }
}

// Загрузка данных
export function loadFromStorage(key, maxAge = null) {
  if (!isStorageAvailable()) {
    return null;
  }
  
  try {
    const item = localStorage.getItem(getKey(key));
    if (!item) return null;
    
    const parsed = JSON.parse(item);
    
    // Проверка версии
    if (parsed.version !== STORAGE_VERSION) {
      localStorage.removeItem(getKey(key));
      return null;
    }
    
    // Проверка срока годности
    if (maxAge && Date.now() - parsed.timestamp > maxAge) {
      localStorage.removeItem(getKey(key));
      return null;
    }
    
    return parsed.data;
  } catch (e) {
    console.error('Ошибка чтения из localStorage:', e);
    return null;
  }
}

// Удаление данных
export function removeFromStorage(key) {
  if (!isStorageAvailable()) return;
  localStorage.removeItem(getKey(key));
}

// Очистка старых данных
export function clearOldData(maxAge = 7 * 24 * 60 * 60 * 1000) {
  if (!isStorageAvailable()) return;
  
  const keys = Object.keys(localStorage);
  const now = Date.now();
  
  keys.forEach(key => {
    if (key.startsWith(STORAGE_PREFIX)) {
      try {
        const item = JSON.parse(localStorage.getItem(key));
        if (now - item.timestamp > maxAge) {
          localStorage.removeItem(key);
        }
      } catch (e) {
        // Удаляем битые данные
        localStorage.removeItem(key);
      }
    }
  });
}

// Очистка всех данных приложения
export function clearAllStorage() {
  if (!isStorageAvailable()) return;
  
  Object.keys(localStorage)
    .filter(key => key.startsWith(STORAGE_PREFIX))
    .forEach(key => localStorage.removeItem(key));
}

export default {
  save: saveToStorage,
  load: loadFromStorage,
  remove: removeFromStorage,
  clearOld: clearOldData,
  clearAll: clearAllStorage
};