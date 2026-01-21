# 🧭 Conventional Fire Alarm System – Step-Wise Learning & Development Plan

---

## 🔰 PHASE 0 – Orientation (DO NOT SKIP)

**Goal:** Understand *what you are building* before touching hardware.

### Step 0.1 – Understand system behavior (concept only)

Learn these terms (no electronics yet):

* What is a **zone**
* What is **EOL resistor**
* Fire vs Open vs Short vs Normal
* Why fire is **latched**
* Why open wire is a **fault**

📌 Output of this step:
👉 You can explain system behavior on paper.

---

### Step 0.2 – Reverse think your panel (from photo)

From your panel image, write:

* Number of zones
* LEDs per zone
* Buttons
* Outputs (hooter / relay)

📌 Output:
👉 A hand-drawn **block diagram**

---

## 🧪 PHASE 1 – Electronics Fundamentals (minimal, focused)

**Goal:** Learn only the electronics needed (not everything).

---

### Step 1.1 – Learn current sensing (VERY IMPORTANT)

Study:

* Shunt resistor
* Voltage = I × R
* How ADC measures voltage

🧠 Mental model:

> “Panel does not detect smoke.
> Panel detects **current change**.”

📌 Output:
👉 You can calculate current from ADC value.

---

### Step 1.2 – Learn comparator vs ADC

* Comparator → hardware threshold
* ADC → software threshold

You will use:

* **ADC first** (simpler)

📌 Output:
👉 You know when to use ADC vs comparator.

---

## ⚡ PHASE 2 – Power Before Everything

**Goal:** Make system power stable and safe.

---

### Step 2.1 – Learn fire panel power architecture

Understand:

* 230VAC → 24VDC
* Battery backup (12V SLA ×2)
* Why 24V is used

📌 Output:
👉 Power block diagram only.

---

### Step 2.2 – Build a SAFE lab power setup

For now:

* Use **24V SMPS**
* Use **5V buck** for MCU
* Ignore battery initially

🚫 DO NOT design charger yet.

📌 Output:
👉 MCU runs safely from 24V system.

---

## 🧠 PHASE 3 – MCU + ADC (Coder Friendly Phase)

**Goal:** Connect software to real analog signals.

---

### Step 3.1 – Select MCU (simple)

Choose one:

* STM32F103
* ATmega328
* PIC16F (if curious)

Requirement:

* ADC
* GPIO
* Watchdog

📌 Output:
👉 Toolchain ready, LED blink done.

---

### Step 3.2 – Learn ADC practically

Do this:

* Read pot value
* Print ADC via UART
* Convert ADC → voltage

📌 Output:
👉 Confidence with ADC readings.

---

## 🔌 PHASE 4 – Single Zone Prototype (CORE PHASE)

**Goal:** Build ONE working fire zone.

---

### Step 4.1 – Build zone hardware

Components:

* 24V source
* Rsense resistor
* Terminal block
* Op-amp (optional at start)

Simulate:

* Normal → resistor
* Fire → lower resistor
* Open → disconnect
* Short → wire short

📌 Output:
👉 ADC changes when you change resistor.

---

### Step 4.2 – Write zone detection code

Implement logic:

```c
if(adc < OPEN_TH) state = OPEN;
else if(adc < NORMAL_TH) state = NORMAL;
else if(adc < FIRE_TH) state = FIRE;
else state = SHORT;
```

📌 Output:
👉 One zone correctly detected.

---

## 🚨 PHASE 5 – Fire Logic (Safety Thinking)

**Goal:** Think like a safety engineer.

---

### Step 5.1 – Fire must LATCH

Once fire detected:

* It stays fire
* Until RESET pressed

📌 Output:
👉 Fire latch logic working.

---

### Step 5.2 – Button handling

Implement:

* RESET
* SILENCE
* ACK

📌 Output:
👉 Buttons control system safely.

---

## 🔊 PHASE 6 – Outputs & Indication

**Goal:** Interface with real world.

---

### Step 6.1 – LED indications

Each zone:

* Green → Normal
* Red → Fire
* Yellow → Fault

📌 Output:
👉 Visual feedback works.

---

### Step 6.2 – Relay & hooter

Add:

* Fire relay
* Buzzer / hooter

Safety:

* Flyback diode
* Separate supply line

📌 Output:
👉 Alarm sounds on fire.

---

## 🧱 PHASE 7 – Multi-Zone Scaling

**Goal:** Turn prototype into product.

---

### Step 7.1 – Duplicate zone hardware

* 4 zones
* Same circuit replicated

📌 Output:
👉 All zones detected independently.

---

### Step 7.2 – Software structuring

Use:

```c
struct zone {
    uint16_t adc;
    uint8_t state;
};
```

📌 Output:
👉 Clean scalable code.

---

## 🔋 PHASE 8 – Battery & Faults (Advanced)

**Goal:** Handle real-world failures.

---

### Step 8.1 – Battery basics

Learn:

* SLA charging concept
* Battery low detection

📌 Output:
👉 Panel survives power failure.

---

### Step 8.2 – Fault monitoring

Add:

* Mains fail
* Battery low
* Charger fail

📌 Output:
👉 Fault LED works.

---

## 🧪 PHASE 9 – Testing Like Industry

**Goal:** Make system reliable.

Test:

* Wire cut
* Short circuit
* Power loss
* MCU reset during fire

📌 Output:
👉 Predictable behavior.

---

## 🏭 PHASE 10 – Product Mindset

**Goal:** Think beyond prototype.

* Metal enclosure
* Cable glands
* Earth grounding
* EMI reduction

📌 Output:
👉 Industry-style panel.

---
