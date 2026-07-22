"""
conftest.py — Shared Pytest fixtures and helpers for StudyVoice AI Selenium E2E Tests.

Provides:
- Chrome headless WebDriver setup/teardown
- Screenshot capture on test failure
- Base URL configuration
- Common navigation and interaction helpers
"""

import os
import time
import pytest
import json
from datetime import datetime
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import (
    TimeoutException, NoSuchElementException,
    ElementNotInteractableException, StaleElementReferenceException
)

# ─── Configuration ───────────────────────────────────────────────────────────

BASE_URL = os.environ.get("TEST_BASE_URL", "http://localhost:8080")
SCREENSHOT_DIR = os.path.join(os.path.dirname(__file__), "screenshots")
IMPLICIT_WAIT = 5
EXPLICIT_WAIT = 10
PAGE_LOAD_TIMEOUT = 30


# ─── Fixtures ────────────────────────────────────────────────────────────────

@pytest.fixture(scope="session")
def browser_options():
    """Configure Chrome options for headless testing."""
    options = Options()
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--disable-extensions")
    options.add_argument("--disable-popup-blocking")
    options.add_argument("--disable-notifications")
    options.add_argument("--ignore-certificate-errors")
    options.add_argument("--disable-web-security")
    options.add_argument("--allow-running-insecure-content")
    # Disable speech synthesis in headless
    options.add_argument("--autoplay-policy=no-user-gesture-required")
    return options


def _create_driver(options):
    """Helper to create Chrome driver using ChromeDriverManager with fallback."""
    try:
        from webdriver_manager.chrome import ChromeDriverManager
        service = Service(ChromeDriverManager().install())
        return webdriver.Chrome(service=service, options=options)
    except Exception:
        return webdriver.Chrome(options=options)


@pytest.fixture(scope="function")
def driver(browser_options, request):
    """Create a fresh Chrome WebDriver instance for each test."""
    chrome_driver = _create_driver(browser_options)
    chrome_driver.implicitly_wait(IMPLICIT_WAIT)
    chrome_driver.set_page_load_timeout(PAGE_LOAD_TIMEOUT)

    yield chrome_driver

    # Take screenshot on failure
    if hasattr(request.node, "rep_call") and request.node.rep_call.failed:
        _take_screenshot(chrome_driver, request.node.name)

    chrome_driver.quit()


@pytest.fixture(scope="function")
def driver_mobile(browser_options):
    """Chrome WebDriver with mobile viewport (375x812 — iPhone X)."""
    mobile_options = Options()
    for arg in browser_options.arguments:
        if "window-size" not in arg:
            mobile_options.add_argument(arg)
    mobile_options.add_argument("--window-size=375,812")

    chrome_driver = _create_driver(mobile_options)
    chrome_driver.implicitly_wait(IMPLICIT_WAIT)
    chrome_driver.set_page_load_timeout(PAGE_LOAD_TIMEOUT)

    yield chrome_driver
    chrome_driver.quit()


@pytest.fixture(scope="function")
def driver_tablet(browser_options):
    """Chrome WebDriver with tablet viewport (768x1024 — iPad)."""
    tablet_options = Options()
    for arg in browser_options.arguments:
        if "window-size" not in arg:
            tablet_options.add_argument(arg)
    tablet_options.add_argument("--window-size=768,1024")

    chrome_driver = _create_driver(tablet_options)
    chrome_driver.implicitly_wait(IMPLICIT_WAIT)
    chrome_driver.set_page_load_timeout(PAGE_LOAD_TIMEOUT)

    yield chrome_driver
    chrome_driver.quit()


@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """Attach test outcome to the request node for screenshot capture."""
    outcome = yield
    rep = outcome.get_result()
    setattr(item, f"rep_{rep.when}", rep)


# ─── Helper Functions ────────────────────────────────────────────────────────

def get_base_url():
    """Return the base URL for the app under test."""
    return BASE_URL


def navigate_to(driver, path=""):
    """Navigate to a specific path relative to base URL."""
    url = f"{BASE_URL}{path}"
    driver.get(url)
    wait_for_page_load(driver)
    time.sleep(1)  # Allow React Splash screen (500ms timer in App.jsx) to clear


def wait_for_page_load(driver, timeout=PAGE_LOAD_TIMEOUT):
    """Wait until the page is fully loaded."""
    WebDriverWait(driver, timeout).until(
        lambda d: d.execute_script("return document.readyState") == "complete"
    )


def wait_for_element(driver, by, value, timeout=EXPLICIT_WAIT):
    """Wait for an element to be present and return it."""
    return WebDriverWait(driver, timeout).until(
        EC.presence_of_element_located((by, value))
    )


def wait_for_element_visible(driver, by, value, timeout=EXPLICIT_WAIT):
    """Wait for an element to be visible and return it."""
    return WebDriverWait(driver, timeout).until(
        EC.visibility_of_element_located((by, value))
    )


def wait_for_element_clickable(driver, by, value, timeout=EXPLICIT_WAIT):
    """Wait for an element to be clickable and return it."""
    return WebDriverWait(driver, timeout).until(
        EC.element_to_be_clickable((by, value))
    )


def wait_for_text_in_element(driver, by, value, text, timeout=EXPLICIT_WAIT):
    """Wait until an element contains specific text."""
    return WebDriverWait(driver, timeout).until(
        EC.text_to_be_present_in_element((by, value), text)
    )


def wait_for_url_contains(driver, url_fragment, timeout=EXPLICIT_WAIT):
    """Wait until the URL contains a specific fragment."""
    return WebDriverWait(driver, timeout).until(
        EC.url_contains(url_fragment)
    )


def find_elements_by_text(driver, tag, text):
    """Find elements by their visible text content."""
    elements = driver.find_elements(By.TAG_NAME, tag)
    return [el for el in elements if text.lower() in el.text.lower()]


def find_input_by_placeholder(driver, placeholder):
    """Find an input element by its placeholder attribute."""
    return driver.find_element(By.CSS_SELECTOR, f'input[placeholder="{placeholder}"]')


def find_button_by_text(driver, text):
    """Find a button element by its visible text."""
    buttons = driver.find_elements(By.TAG_NAME, "button")
    for btn in buttons:
        if text.lower() in btn.text.lower():
            return btn
    return None


def find_link_by_text(driver, text):
    """Find a link element by its visible text."""
    links = driver.find_elements(By.TAG_NAME, "a")
    for link in links:
        if text.lower() in link.text.lower():
            return link
    return None


def element_exists(driver, by, value):
    """Check if an element exists in the DOM."""
    try:
        driver.find_element(by, value)
        return True
    except NoSuchElementException:
        return False


def get_computed_style(driver, element, property_name):
    """Get a computed CSS style property of an element."""
    return driver.execute_script(
        f"return window.getComputedStyle(arguments[0]).getPropertyValue('{property_name}');",
        element
    )


def get_css_variable(driver, variable_name):
    """Get the value of a CSS custom property from :root."""
    return driver.execute_script(
        f"return getComputedStyle(document.documentElement).getPropertyValue('{variable_name}').trim();"
    )


def inject_js(driver, script):
    """Execute JavaScript in the browser and return the result."""
    return driver.execute_script(script)


def get_console_logs(driver):
    """Get browser console logs."""
    try:
        return driver.get_log("browser")
    except Exception:
        return []


def get_page_title(driver):
    """Get the page title."""
    return driver.title


def get_current_url(driver):
    """Get the current URL."""
    return driver.current_url


def scroll_to_element(driver, element):
    """Scroll an element into view."""
    driver.execute_script("arguments[0].scrollIntoView({behavior: 'smooth', block: 'center'});", element)


def scroll_to_bottom(driver):
    """Scroll to the bottom of the page."""
    driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")


def get_viewport_size(driver):
    """Get the current viewport dimensions."""
    return {
        "width": driver.execute_script("return window.innerWidth;"),
        "height": driver.execute_script("return window.innerHeight;")
    }


def clear_local_storage(driver):
    """Clear all localStorage data."""
    driver.execute_script("window.localStorage.clear();")


def set_local_storage(driver, key, value):
    """Set a value in localStorage."""
    if isinstance(value, (dict, list)):
        value = json.dumps(value)
    driver.execute_script(f"window.localStorage.setItem('{key}', '{value}');")


def get_local_storage(driver, key):
    """Get a value from localStorage."""
    return driver.execute_script(f"return window.localStorage.getItem('{key}');")


def simulate_dark_mode(driver):
    """Simulate dark mode by adding dark-mode class to body."""
    driver.execute_script("document.body.classList.add('dark-mode');")


def simulate_light_mode(driver):
    """Remove dark mode class from body."""
    driver.execute_script("document.body.classList.remove('dark-mode');")


def wait_seconds(seconds):
    """Simple wait helper."""
    time.sleep(seconds)


def _take_screenshot(driver, test_name):
    """Take a screenshot and save it to the screenshots directory."""
    os.makedirs(SCREENSHOT_DIR, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{test_name}_{timestamp}.png"
    filepath = os.path.join(SCREENSHOT_DIR, filename)
    try:
        driver.save_screenshot(filepath)
    except Exception:
        pass


def measure_page_load_time(driver, url):
    """Measure how long a page takes to fully load."""
    start = time.time()
    driver.get(url)
    wait_for_page_load(driver)
    return time.time() - start


def count_dom_elements(driver):
    """Count total DOM elements on the page."""
    return driver.execute_script("return document.querySelectorAll('*').length;")


def get_all_links(driver):
    """Get all anchor elements on the page."""
    return driver.find_elements(By.TAG_NAME, "a")


def get_all_images(driver):
    """Get all image elements on the page."""
    return driver.find_elements(By.TAG_NAME, "img")


def get_all_inputs(driver):
    """Get all input elements on the page."""
    return driver.find_elements(By.TAG_NAME, "input")


def get_all_buttons(driver):
    """Get all button elements on the page."""
    return driver.find_elements(By.TAG_NAME, "button")


def check_element_overflow(driver, element):
    """Check if an element has content overflow."""
    return driver.execute_script(
        "return arguments[0].scrollHeight > arguments[0].clientHeight || "
        "arguments[0].scrollWidth > arguments[0].clientWidth;",
        element
    )
