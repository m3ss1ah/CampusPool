require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

async function seed() {
  try {
    console.log('Connecting to database...');
    
    // Check if we have at least one user to be the creator
    const userRes = await pool.query('SELECT id FROM users LIMIT 1');
    if (userRes.rows.length === 0) {
      console.log('No users found. Please create a user first (e.g. by logging in once).');
      process.exit(1);
    }
    const creatorId = userRes.rows[0].id;

    console.log(`Using user ${creatorId} as creator.`);

    const rides = [
      {
        source: 'Hostel A', dest: 'Engineering Block',
        lat: 19.0760, lng: 72.8777,
        dlat: 19.0780, dlng: 72.8800,
        type: 'car', seats: 3, offsetDays: 1,
      },
      {
        source: 'Main Gate', dest: 'Library',
        lat: 19.0740, lng: 72.8750,
        dlat: 19.0720, dlng: 72.8730,
        type: 'bike', seats: 1, offsetDays: 2,
      },
      {
        source: 'Cafeteria', dest: 'Sports Complex',
        lat: 19.0775, lng: 72.8765,
        dlat: 19.0800, dlng: 72.8720,
        type: 'car', seats: 4, offsetDays: 3,
      },
      {
        source: 'Library', dest: 'Hostel B',
        lat: 19.0720, lng: 72.8730,
        dlat: 19.0750, dlng: 72.8790,
        type: 'bike', seats: 1, offsetDays: 4,
      },
      {
        source: 'Science Block', dest: 'Main Gate',
        lat: 19.0790, lng: 72.8755,
        dlat: 19.0740, dlng: 72.8750,
        type: 'car', seats: 2, offsetDays: 5,
      }
    ];

    console.log('Inserting test rides...');
    for (const r of rides) {
      const departureTime = new Date();
      departureTime.setDate(departureTime.getDate() + r.offsetDays);
      departureTime.setHours(9, 0, 0, 0); // 9 AM

      await pool.query(
        `INSERT INTO commutes (
          creator_id, source_label, source_location,
          dest_label, dest_label_normalized, dest_location,
          departure_time, total_seats, available_seats,
          vehicle_type, notes
        ) VALUES (
          $1, $2, ST_GeogFromText($3),
          $4, $5, ST_GeogFromText($6),
          $7, $8, $8, $9, $10
        )`,
        [
          creatorId,
          r.source, `POINT(${r.lng} ${r.lat})`,
          r.dest, r.dest.toLowerCase().replace(/[^a-z0-9]/g, ''), `POINT(${r.dlng} ${r.dlat})`,
          departureTime.toISOString(),
          r.seats,
          r.type,
          'Test ride created by seed script'
        ]
      );
    }

    console.log('Successfully seeded test rides!');
  } catch (e) {
    console.error('Error seeding rides:', e);
  } finally {
    pool.end();
  }
}

seed();
