<?php

use App\Core\Csrf;
use App\Models\Property;

/** @var ?array $property */
/** @var array $images */
/** @var array $categories */
/** @var array $errors */
/** @var array $old */

$isEdit = $property !== null;
$action = $isEdit ? '/admin/properties/' . (int)$property['id'] : '/admin/properties';

$val = static function (string $key, $default = '') use ($old, $property) {
    if (array_key_exists($key, $old)) {
        return $old[$key];
    }
    if ($property !== null && array_key_exists($key, $property)) {
        return $property[$key];
    }
    return $default;
};
$checked = static function (string $key) use ($old, $property): bool {
    if ($old !== []) {
        return !empty($old[$key]);
    }
    return $property !== null && !empty($property[$key]);
};
$selectedAmenities = [];
if (array_key_exists('amenities', $old) && is_array($old['amenities'])) {
    $selectedAmenities = $old['amenities'];
} elseif ($property !== null && !empty($property['amenities'])) {
    $decoded = json_decode((string)$property['amenities'], true);
    if (is_array($decoded)) {
        $selectedAmenities = $decoded;
    }
}
$err = static fn(string $key) => isset($errors[$key])
    ? '<div class="field-error">' . e($errors[$key]) . '</div>' : '';
?>
<?php if ($errors !== []): ?>
<div class="alert alert-error">Please fix the highlighted fields below.</div>
<?php endif; ?>

<form method="post" action="<?= e($action) ?>" enctype="multipart/form-data" class="property-form">
  <?= Csrf::field() ?>
  <?php /* Default submit target: without this, Enter in a text field would trigger the
           first submit button in the form — the image-delete formaction button. */ ?>
  <button type="submit" hidden aria-hidden="true" tabindex="-1"></button>

  <div class="form-grid">
    <div class="card form-card span-2">
      <div class="card-head"><h2>Listing</h2></div>
      <div class="grid-2">
        <label class="field">
          <span class="field-label">Title (EN) *</span>
          <input type="text" name="title" value="<?= e($val('title')) ?>" required>
          <?= $err('title') ?>
        </label>
        <label class="field">
          <span class="field-label">Title (日本語) *</span>
          <input type="text" name="title_ja" value="<?= e($val('title_ja')) ?>" required>
          <?= $err('title_ja') ?>
        </label>
      </div>
      <div class="grid-2">
        <label class="field">
          <span class="field-label">Description (EN)</span>
          <textarea name="description" rows="5"><?= e($val('description')) ?></textarea>
        </label>
        <label class="field">
          <span class="field-label">Description (日本語)</span>
          <textarea name="description_ja" rows="5"><?= e($val('description_ja')) ?></textarea>
        </label>
      </div>
      <div class="grid-4">
        <label class="field">
          <span class="field-label">Transaction *</span>
          <select name="transaction_type">
            <option value="rent" <?= $val('transaction_type', 'rent') === 'rent' ? 'selected' : '' ?>>Rent 賃貸</option>
            <option value="buy" <?= $val('transaction_type') === 'buy' ? 'selected' : '' ?>>Buy 売買</option>
          </select>
        </label>
        <label class="field">
          <span class="field-label">Status</span>
          <select name="status">
            <option value="draft" <?= $val('status', 'draft') === 'draft' ? 'selected' : '' ?>>Draft</option>
            <option value="published" <?= $val('status') === 'published' ? 'selected' : '' ?>>Published</option>
          </select>
        </label>
        <label class="field">
          <span class="field-label">Category</span>
          <select name="category_id">
            <option value="">— None —</option>
            <?php foreach ($categories as $cat): ?>
            <option value="<?= e($cat['id']) ?>" <?= (string)$val('category_id') === (string)$cat['id'] ? 'selected' : '' ?>>
              <?= e($cat['name']) ?> / <?= e($cat['name_ja']) ?>
            </option>
            <?php endforeach; ?>
          </select>
        </label>
        <label class="field check-field">
          <input type="checkbox" name="is_featured" value="1" <?= $checked('is_featured') ? 'checked' : '' ?>>
          <span>Featured ★</span>
        </label>
      </div>
    </div>

    <div class="card form-card">
      <div class="card-head"><h2>Pricing</h2></div>
      <label class="field">
        <span class="field-label">Price (JPY) *</span>
        <input type="number" name="price" min="0" step="1" value="<?= e($val('price')) ?>" required>
        <?= $err('price') ?>
      </label>
      <label class="field">
        <span class="field-label">Management fee (JPY/mo)</span>
        <input type="number" name="management_fee" min="0" step="1" value="<?= e($val('management_fee')) ?>">
      </label>
      <div class="grid-2">
        <label class="field">
          <span class="field-label">Deposit (months)</span>
          <input type="number" name="deposit_months" min="0" step="0.1" value="<?= e($val('deposit_months')) ?>">
        </label>
        <label class="field">
          <span class="field-label">Key money (months)</span>
          <input type="number" name="key_money_months" min="0" step="0.1" value="<?= e($val('key_money_months')) ?>">
        </label>
      </div>
    </div>

    <div class="card form-card">
      <div class="card-head"><h2>Building</h2></div>
      <div class="grid-2">
        <label class="field">
          <span class="field-label">Layout</span>
          <select name="layout">
            <option value="">—</option>
            <?php foreach (Property::LAYOUTS as $layout): ?>
            <option value="<?= e($layout) ?>" <?= $val('layout') === $layout ? 'selected' : '' ?>><?= e($layout) ?></option>
            <?php endforeach; ?>
          </select>
        </label>
        <label class="field">
          <span class="field-label">Size (m²)</span>
          <input type="number" name="size_sqm" min="0" step="0.1" value="<?= e($val('size_sqm')) ?>">
        </label>
      </div>
      <div class="grid-3">
        <label class="field">
          <span class="field-label">Built year</span>
          <input type="number" name="built_year" min="1900" max="2100" value="<?= e($val('built_year')) ?>">
        </label>
        <label class="field">
          <span class="field-label">Floor</span>
          <input type="number" name="floor" value="<?= e($val('floor')) ?>">
        </label>
        <label class="field">
          <span class="field-label">Total floors</span>
          <input type="number" name="total_floors" value="<?= e($val('total_floors')) ?>">
        </label>
      </div>
      <div class="grid-2">
        <label class="field check-field">
          <input type="checkbox" name="pet_allowed" value="1" <?= $checked('pet_allowed') ? 'checked' : '' ?>>
          <span>Pets allowed ペット可</span>
        </label>
        <label class="field check-field">
          <input type="checkbox" name="parking_available" value="1" <?= $checked('parking_available') ? 'checked' : '' ?>>
          <span>Parking 駐車場</span>
        </label>
      </div>
    </div>

    <div class="card form-card span-2">
      <div class="card-head"><h2>Location</h2></div>
      <div class="grid-2">
        <label class="field">
          <span class="field-label">Address (EN) *</span>
          <input type="text" name="address" value="<?= e($val('address')) ?>" required>
          <?= $err('address') ?>
        </label>
        <label class="field">
          <span class="field-label">Address (日本語) *</span>
          <input type="text" name="address_ja" value="<?= e($val('address_ja')) ?>" required>
          <?= $err('address_ja') ?>
        </label>
      </div>
      <div class="grid-4">
        <label class="field">
          <span class="field-label">Prefecture</span>
          <input type="text" name="prefecture" value="<?= e($val('prefecture')) ?>">
        </label>
        <label class="field">
          <span class="field-label">City / Ward</span>
          <input type="text" name="city" value="<?= e($val('city')) ?>">
        </label>
        <label class="field">
          <span class="field-label">Latitude</span>
          <input type="number" name="latitude" step="0.000001" min="-90" max="90" value="<?= e($val('latitude')) ?>">
        </label>
        <label class="field">
          <span class="field-label">Longitude</span>
          <input type="number" name="longitude" step="0.000001" min="-180" max="180" value="<?= e($val('longitude')) ?>">
        </label>
      </div>
      <div class="grid-3">
        <label class="field">
          <span class="field-label">Nearest station (EN)</span>
          <input type="text" name="nearest_station" value="<?= e($val('nearest_station')) ?>">
        </label>
        <label class="field">
          <span class="field-label">Nearest station (日本語)</span>
          <input type="text" name="nearest_station_ja" value="<?= e($val('nearest_station_ja')) ?>">
        </label>
        <label class="field">
          <span class="field-label">Walk to station (min)</span>
          <input type="number" name="station_walk_min" min="0" value="<?= e($val('station_walk_min')) ?>">
        </label>
      </div>
    </div>

    <div class="card form-card span-2">
      <div class="card-head"><h2>Amenities 設備</h2></div>
      <div class="amenity-grid">
        <?php foreach (Property::AMENITIES as $amenity): ?>
        <label class="check-field">
          <input type="checkbox" name="amenities[]" value="<?= e($amenity) ?>"
            <?= in_array($amenity, $selectedAmenities, true) ? 'checked' : '' ?>>
          <span><?= e(str_replace('_', ' ', $amenity)) ?></span>
        </label>
        <?php endforeach; ?>
      </div>
    </div>

    <div class="card form-card span-2">
      <div class="card-head"><h2>Images</h2></div>
      <?php if ($images !== []): ?>
      <div class="image-list">
        <?php foreach ($images as $img): ?>
        <div class="image-item">
          <img src="<?= e($img['url']) ?>" alt="" loading="lazy">
          <div class="image-meta">
            <label class="field field-inline">
              <span class="field-label">Sort</span>
              <input type="number" name="image_order[<?= e($img['id']) ?>]" value="<?= e($img['sort_order']) ?>" min="0" class="sort-input">
            </label>
            <button type="submit" class="btn btn-danger btn-sm"
              formaction="/admin/properties/<?= e((int)$property['id']) ?>/images/<?= e($img['id']) ?>/delete"
              formnovalidate
              data-confirm="Delete this image?">Delete</button>
          </div>
        </div>
        <?php endforeach; ?>
      </div>
      <?php endif; ?>
      <div class="grid-2">
        <label class="field">
          <span class="field-label">Upload images (jpg / png / webp, max 8 MB each)</span>
          <input type="file" name="images[]" accept="image/jpeg,image/png,image/webp" multiple data-preview="upload-preview">
          <div class="upload-preview" id="upload-preview"></div>
        </label>
        <label class="field">
          <span class="field-label">Add images by URL (one per line)</span>
          <textarea name="image_urls" rows="4" placeholder="https://images.unsplash.com/photo-…"></textarea>
        </label>
      </div>
      <label class="field">
        <span class="field-label">Floor plan URL</span>
        <input type="url" name="floor_plan_url" value="<?= e($val('floor_plan_url')) ?>" placeholder="https://…/floorplan.png">
      </label>
    </div>

    <div class="card form-card span-2">
      <div class="card-head"><h2>Agent</h2></div>
      <div class="grid-4">
        <label class="field">
          <span class="field-label">Agent name</span>
          <input type="text" name="agent_name" value="<?= e($val('agent_name')) ?>">
        </label>
        <label class="field">
          <span class="field-label">Company</span>
          <input type="text" name="agent_company" value="<?= e($val('agent_company', 'HappyHome Realty K.K.')) ?>">
        </label>
        <label class="field">
          <span class="field-label">Phone</span>
          <input type="text" name="agent_phone" value="<?= e($val('agent_phone')) ?>">
        </label>
        <label class="field">
          <span class="field-label">Email</span>
          <input type="email" name="agent_email" value="<?= e($val('agent_email')) ?>">
        </label>
      </div>
    </div>
  </div>

  <div class="form-actions">
    <a href="/admin/properties" class="btn btn-ghost">Cancel</a>
    <button type="submit" class="btn btn-primary"><?= $isEdit ? 'Save changes' : 'Create property' ?></button>
  </div>
</form>
