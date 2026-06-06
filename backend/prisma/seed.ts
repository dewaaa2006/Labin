import bcrypt from 'bcryptjs';
import { PrismaClient, Role } from '@prisma/client';

const prisma = new PrismaClient();

async function user(data: {
  name: string;
  email: string;
  password: string;
  role: Role;
  nim?: string;
  university?: string;
  faculty?: string;
  studyProgram?: string;
}) {
  return prisma.user.upsert({
    where: { email: data.email },
    update: { role: data.role, name: data.name },
    create: {
      ...data,
      university: data.university ?? 'Universitas Labin',
      faculty: data.faculty ?? 'Fakultas Ilmu Komputer',
      studyProgram: data.studyProgram ?? 'Informatika',
      password: await bcrypt.hash(data.password, 12),
    },
  });
}

async function main() {
  const admin = await user({ name: 'Admin Labin', email: 'admin@labin.id', password: 'Admin123!', role: 'ADMIN' });
  const staff1 = await user({ name: 'Dion Pratama', email: 'staff1@labin.id', password: 'Staff123!', role: 'STAFF' });
  const staff2 = await user({ name: 'Naya Putri', email: 'staff2@labin.id', password: 'Staff123!', role: 'STAFF' });
  await user({ name: 'Dr. Bima Santoso', email: 'dosen1@labin.id', password: 'Dosen123!', role: 'LECTURER' });
  await user({ name: 'Dr. Ayu Maharani', email: 'dosen2@labin.id', password: 'Dosen123!', role: 'LECTURER' });
  const students = await Promise.all(
    Array.from({ length: 5 }, (_, i) =>
      user({
        name: ['Rafi Aditya', 'Salsa Kirana', 'Bagas Wicaksono', 'Mira Aulia', 'Fathan Rayyan'][i],
        email: `mahasiswa${i + 1}@labin.id`,
        password: 'Mhs123!',
        role: 'STUDENT',
        nim: `22105110${40 + i}`,
      }),
    ),
  );

  const rooms = await Promise.all([
    prisma.room.upsert({ where: { code: 'LAB-KOM-A' }, update: {}, create: { code: 'LAB-KOM-A', name: 'Lab Komputer A', capacity: 40, floor: '2', building: 'Gedung B', facilities: ['AC', 'Proyektor', 'Internet', 'Whiteboard'], description: 'Ruang praktikum pemrograman dan mobile.' } }),
    prisma.room.upsert({ where: { code: 'LAB-KOM-B' }, update: {}, create: { code: 'LAB-KOM-B', name: 'Lab Komputer B', capacity: 36, floor: '2', building: 'Gedung B', facilities: ['AC', 'Internet'], description: 'Ruang kelas dan praktikum.' } }),
    prisma.room.upsert({ where: { code: 'LAB-STUDIO' }, update: {}, create: { code: 'LAB-STUDIO', name: 'Lab Studio', capacity: 24, floor: '1', building: 'Gedung C', facilities: ['Lighting', 'Green Screen', 'Audio Interface'], description: 'Ruang produksi konten multimedia.' } }),
    prisma.room.upsert({ where: { code: 'LAB-JARINGAN' }, update: {}, create: { code: 'LAB-JARINGAN', name: 'Lab Jaringan', capacity: 32, floor: '3', building: 'Gedung B', facilities: ['Rack Server', 'Router', 'Switch', 'Internet'], description: 'Ruang praktikum jaringan.' } }),
  ]);

  const equipmentSeeds = [
    ['Workstation Dell OptiPlex 7090', 'COMPUTER', 18],
    ['Laptop Asus ROG Zephyrus G14', 'COMPUTER', 6],
    ['Mac Mini M2 Development Kit', 'COMPUTER', 4],
    ['Monitor Dell UltraSharp 27', 'COMPUTER', 12],
    ['Tablet Samsung Tab S9', 'COMPUTER', 8],
    ['Kamera DSLR Canon EOS 90D', 'STUDIO', 3],
    ['Drone DJI Mini 3 Pro', 'STUDIO', 2],
    ['Mikrofon Kondenser Rode NT1', 'STUDIO', 4],
    ['Lighting Kit Godox SL60W', 'STUDIO', 5],
    ['Router MikroTik RB951', 'NETWORK', 10],
    ['Switch Cisco Catalyst 2960', 'NETWORK', 6],
    ['Access Point Ubiquiti U6 Lite', 'NETWORK', 8],
    ['Crimping Tool RJ45', 'NETWORK', 12],
    ['Tripod Video Manfrotto', 'MULTIMEDIA', 4],
    ['Audio Mixer Yamaha MG10XU', 'MULTIMEDIA', 2],
    ['Arduino Uno R3 Kit', 'ELECTRONICS', 20],
    ['Raspberry Pi 5 Kit', 'ELECTRONICS', 10],
    ['Digital Multimeter Sanwa', 'MEASUREMENT', 10],
    ['Oscilloscope Digital Rigol', 'MEASUREMENT', 3],
    ['Function Generator GW Instek', 'MEASUREMENT', 2],
  ] as const;

  const equipment = [];
  for (const [name, category, stock] of equipmentSeeds) {
    equipment.push(await prisma.equipment.create({
      data: {
        name,
        category,
        description: `${name} untuk kegiatan praktikum, penelitian, dan produksi lab.`,
        specifications: `Stok ${stock}, standar operasional lab tersedia.`,
        totalStock: stock,
        availableStock: Math.max(0, stock - Math.floor(stock / 3)),
        condition: stock <= 3 ? 'FAIR' : 'GOOD',
      },
    }));
  }

  const now = new Date();
  for (let i = 0; i < 12; i++) {
    await prisma.loan.create({
      data: {
        trackingId: `LBN-20260606-${String(i + 1).padStart(3, '0')}`,
        userId: students[i % students.length].id,
        equipmentId: equipment[i % equipment.length].id,
        quantity: 1,
        borrowDate: new Date(now.getTime() - i * 86400000),
        returnDate: new Date(now.getTime() + (3 + i) * 86400000),
        purpose: 'Kebutuhan praktikum dan tugas mata kuliah pemrograman mobile.',
        status: ['PENDING', 'APPROVED', 'TAKEN', 'RETURNED'][i % 4] as any,
      },
    });
  }

  for (let i = 0; i < 10; i++) {
    const date = new Date(now);
    date.setDate(now.getDate() + i);
    await prisma.booking.create({
      data: {
        trackingId: `BKN-20260606-${String(i + 1).padStart(3, '0')}`,
        userId: students[i % students.length].id,
        roomId: rooms[i % rooms.length].id,
        date,
        startTime: `${String(7 + (i % 8)).padStart(2, '0')}:00`,
        endTime: `${String(9 + (i % 8)).padStart(2, '0')}:00`,
        activityName: ['Praktikum Mobile', 'Penelitian IoT', 'Kelas Jaringan', 'Workshop UI/UX'][i % 4],
        activityType: ['PRACTICUM', 'RESEARCH', 'LECTURE', 'ORGANIZATION'][i % 4] as any,
        participants: 20 + i,
        status: ['PENDING', 'APPROVED', 'DONE'][i % 3] as any,
      },
    });
  }

  await prisma.announcement.createMany({
    data: [
      { authorId: admin.id, title: 'Maintenance Lab Studio 7-9 Juni', content: 'Lab Studio ditutup sementara untuk perawatan perangkat audio visual.', category: 'MAINTENANCE', isPinned: true, publishedAt: now },
      { authorId: admin.id, title: 'Rekrutmen Student Staff Dibuka', content: 'Daftar sebelum 15 Juni 2026 dan bantu operasional lab kampus.', category: 'RECRUITMENT', isPinned: false, publishedAt: now },
      { authorId: admin.id, title: 'SOP Peminjaman Alat Diperbarui', content: 'Mahasiswa wajib mengunggah KTM dan surat izin untuk alat bernilai tinggi.', category: 'GENERAL', isPinned: false, publishedAt: now },
    ],
  });

  await prisma.damageReport.create({
    data: {
      trackingId: 'RPT-20260606-001',
      userId: students[0].id,
      location: 'Lab Komputer A',
      facilityName: 'Proyektor',
      description: 'Proyektor tidak menampilkan gambar dari HDMI dan lampu indikator berkedip.',
      urgency: 'HIGH',
      status: 'IN_PROGRESS',
      photos: [],
    },
  });

  await prisma.staffShift.createMany({
    data: [
      { userId: staff1.id, roomId: rooms[0].id, date: now, startTime: '08:00', endTime: '12:00' },
      { userId: staff2.id, roomId: rooms[2].id, date: now, startTime: '13:00', endTime: '17:00' },
    ],
  });

  await prisma.notification.createMany({
    data: students.map((student) => ({
      userId: student.id,
      title: 'Selamat datang di Labin',
      message: 'Akun kamu siap digunakan untuk peminjaman alat dan reservasi lab.',
      type: 'SYSTEM',
    })),
  });

  console.log('Seed complete. Login: admin@labin.id / Admin123!');
}

main().finally(async () => prisma.$disconnect());
