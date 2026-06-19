self.importScripts('https://cdn.jsdelivr.net/npm/qrcode-generator@1.4.4/qrcode.min.js');

const encoder = new TextEncoder();

self.onmessage = async (event) => {
  const payload = event.data || {};
  const students = payload.students || [];
  const sectionName = payload.sectionName || 'students_qr';
  const gradeSection = payload.gradeSection || '';

  try {
    const files = [];
    postProgress(0, students.length, '');

    for (let index = 0; index < students.length; index++) {
      const student = students[index];
      const displayName = studentName(student);
      const png = await temporaryIdPng({
        lrn: student.lrn || '',
        name: displayName.toUpperCase(),
        gradeSection: gradeSection.toUpperCase(),
      });
      files.push({
        name: `${safeFileName(`${student.lastName || ''} ${student.firstName || ''}`)}.png`,
        bytes: png,
      });
      postProgress(index + 1, students.length, displayName);
    }

    postProgress(students.length, students.length, 'Creating ZIP file...');
    const zip = zipStore(files);
    self.postMessage({ type: 'done', bytes: zip.buffer }, [zip.buffer]);
  } catch (error) {
    self.postMessage({
      type: 'error',
      message: error && error.message ? error.message : String(error),
    });
  }
};

async function temporaryIdPng({ lrn, name, gradeSection }) {
  const qr = qrcode(0, 'M');
  qr.addData(lrn);
  qr.make();

  const width = 720;
  const height = 980;
  const qrSize = 430;
  const qrLeft = (width - qrSize) / 2;
  const qrTop = 86;
  const moduleCount = qr.getModuleCount();
  const quietZone = 4;
  const moduleSize = Math.floor(qrSize / (moduleCount + quietZone * 2));
  const renderedSize = moduleSize * (moduleCount + quietZone * 2);
  const offset = (qrSize - renderedSize) / 2;

  const canvas = new OffscreenCanvas(width, height);
  const context = canvas.getContext('2d');
  if (!context) {
    throw new Error('Unable to create PNG canvas.');
  }

  context.fillStyle = '#ffffff';
  context.fillRect(0, 0, width, height);

  context.fillStyle = '#0f7d4d';
  context.fillRect(0, 0, width, 72);

  context.fillStyle = '#ffffff';
  context.font = '700 24px Arial, Helvetica, sans-serif';
  context.textBaseline = 'alphabetic';
  context.fillText('TEMPORARY STUDENT ID', 40, 47);

  context.fillStyle = '#ffffff';
  context.fillRect(qrLeft, qrTop, qrSize, qrSize);

  context.fillStyle = '#121c18';
  for (let row = 0; row < moduleCount; row++) {
    for (let col = 0; col < moduleCount; col++) {
      if (!qr.isDark(row, col)) continue;
      const x = qrLeft + offset + (col + quietZone) * moduleSize;
      const y = qrTop + offset + (row + quietZone) * moduleSize;
      context.fillRect(x, y, moduleSize, moduleSize);
    }
  }

  context.fillStyle = '#e3f5eb';
  context.fillRect(40, 570, 639, 330);

  context.fillStyle = '#121c18';
  context.font = '700 42px Arial, Helvetica, sans-serif';
  drawTextToFit(context, name, 74, 674, 570, 42);

  context.font = '700 24px Arial, Helvetica, sans-serif';
  drawTextToFit(context, gradeSection, 74, 742, 570, 24);

  context.font = '24px Arial, Helvetica, sans-serif';
  drawTextToFit(context, `LRN: ${lrn}`, 74, 796, 570, 24);

  context.fillStyle = '#0f7d4d';
  context.font = '700 24px Arial, Helvetica, sans-serif';
  drawTextToFit(
    context,
    'Leon Garcia Sr. National High School',
    74,
    878,
    570,
    24,
  );

  const blob = await canvas.convertToBlob({ type: 'image/png' });
  return new Uint8Array(await blob.arrayBuffer());
}

function postProgress(current, total, studentName) {
  self.postMessage({ type: 'progress', current, total, studentName });
}

function studentName(student) {
  const middle = (student.middleName || '').trim();
  const middleInitial = middle ? ` ${middle[0]}.` : '';
  return `${student.lastName || ''}, ${student.firstName || ''}${middleInitial}`.trim();
}

function safeFileName(value) {
  const safe = String(value || '')
    .replace(/[\\/:*?"<>|]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
  return safe || 'student_qr';
}

function drawTextToFit(context, text, x, y, maxWidth, baseSize) {
  const value = String(text || '');
  let size = baseSize;
  while (size > 14 && context.measureText(value).width > maxWidth) {
    size -= 1;
    const weight = context.font.startsWith('700') ? '700 ' : '';
    context.font = `${weight}${size}px Arial, Helvetica, sans-serif`;
  }
  context.fillText(value, x, y);
}

function zipStore(files) {
  const localParts = [];
  const centralParts = [];
  let offset = 0;

  for (const file of files) {
    const nameBytes = encoder.encode(file.name);
    const data = file.bytes;
    const crc = crc32(data);
    const local = concatBytes([
      u32(0x04034b50),
      u16(20),
      u16(0),
      u16(0),
      u16(0),
      u16(0),
      u32(crc),
      u32(data.length),
      u32(data.length),
      u16(nameBytes.length),
      u16(0),
      nameBytes,
      data,
    ]);
    localParts.push(local);

    const central = concatBytes([
      u32(0x02014b50),
      u16(20),
      u16(20),
      u16(0),
      u16(0),
      u16(0),
      u16(0),
      u32(crc),
      u32(data.length),
      u32(data.length),
      u16(nameBytes.length),
      u16(0),
      u16(0),
      u16(0),
      u16(0),
      u32(0),
      u32(offset),
      nameBytes,
    ]);
    centralParts.push(central);
    offset += local.length;
  }

  const centralOffset = offset;
  const central = concatBytes(centralParts);
  const end = concatBytes([
    u32(0x06054b50),
    u16(0),
    u16(0),
    u16(files.length),
    u16(files.length),
    u32(central.length),
    u32(centralOffset),
    u16(0),
  ]);
  return concatBytes([...localParts, central, end]);
}

function concatBytes(parts) {
  const total = parts.reduce((sum, part) => sum + part.length, 0);
  const out = new Uint8Array(total);
  let offset = 0;
  for (const part of parts) {
    out.set(part, offset);
    offset += part.length;
  }
  return out;
}

function u16(value) {
  const out = new Uint8Array(2);
  out[0] = value & 255;
  out[1] = (value >>> 8) & 255;
  return out;
}

function u32(value) {
  const out = new Uint8Array(4);
  out[0] = value & 255;
  out[1] = (value >>> 8) & 255;
  out[2] = (value >>> 16) & 255;
  out[3] = (value >>> 24) & 255;
  return out;
}

const crcTable = (() => {
  const table = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) {
      c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    }
    table[n] = c >>> 0;
  }
  return table;
})();

function crc32(bytes) {
  let crc = 0xffffffff;
  for (let i = 0; i < bytes.length; i++) {
    crc = crcTable[(crc ^ bytes[i]) & 255] ^ (crc >>> 8);
  }
  return (crc ^ 0xffffffff) >>> 0;
}
